"""Offline installer regression tests: python3 -m unittest discover -s tests."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='dotfiles tests ')
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.home = self.base / 'user home'
        self.repo = self.base / 'checkout elsewhere'
        self.home.mkdir()
        self.repo.mkdir()
        for name in ('makesymlinks.sh', 'bashrc', 'profile', 'shellenv', 'aliases'):
            shutil.copy2(ROOT / name, self.repo / name)
        self.env = dict(os.environ, HOME=str(self.home), GIT_CONFIG_NOSYSTEM='1',
                        GIT_CONFIG_GLOBAL=os.devnull)
        self.upstream = self.base / 'upstream'
        self.upstream.mkdir()
        self.git('init', '-q')
        self.git('config', 'user.email', 'test@example.invalid')
        self.git('config', 'user.name', 'Test')
        (self.upstream / 'aliases/available').mkdir(parents=True)
        (self.upstream / 'aliases/available/test.bash').write_text(':\n')
        (self.upstream / 'bash_it.sh').write_text(':\n')
        (self.upstream / '.gitignore').write_text('enabled/\ncustom/\naliases/custom.aliases.bash\n')
        self.git('add', '.')
        self.git('commit', '-qm', 'old')
        self.old = self.git('rev-parse', 'HEAD').stdout.strip()
        (self.upstream / 'bash_it.sh').write_text('# new\n:\n')
        self.git('commit', '-qam', 'new')
        self.new = self.git('rev-parse', 'HEAD').stdout.strip()
        (self.repo / 'bash-it.version').write_text(self.new + '\n')
        (self.repo / 'bash-it.enabled').write_text('150---test.bash ../aliases/available/test.bash\n')
        # Route the installer's production clone URL to a local fixture.
        config = self.base / 'gitconfig'
        config.write_text('[url "' + str(self.upstream) + '"]\n insteadOf = https://github.com/Bash-it/bash-it.git\n')
        self.env['GIT_CONFIG_GLOBAL'] = str(config)

    def run_cmd(self, args, check=True):
        return subprocess.run(args, env=self.env, text=True, capture_output=True, check=check)

    def git(self, *args):
        return self.run_cmd(['git', '-C', str(self.upstream), *args])

    def install(self, check=True):
        return self.run_cmd(['bash', str(self.repo / 'makesymlinks.sh'), '--shell-only'], check)

    def test_fresh_and_repeat(self):
        self.install()
        for name in ('profile', 'shellenv', 'bashrc', 'bash-it'):
            self.assertEqual((self.home / ('.' + name)).resolve(), self.repo / name)
        self.install()
        self.assertFalse((self.home / '.dotfiles_old').exists())

    def test_upgrade_preserves_custom_and_profile_backup(self):
        self.install()
        checkout = self.repo / 'bash-it'
        self.run_cmd(['git', '-C', str(checkout), 'checkout', '--detach', self.old])
        (checkout / 'custom').mkdir()
        (checkout / 'custom/host.bash').write_text('HOST_SETTING=yes\n')
        (checkout / 'enabled/host.bash').symlink_to('../custom/host.bash')
        (self.home / '.profile').unlink()
        (self.home / '.profile').write_text('# host profile\n')
        self.install()
        self.assertEqual((checkout / 'custom/host.bash').read_text(), 'HOST_SETTING=yes\n')
        self.assertTrue((checkout / 'enabled/host.bash').is_file())
        backup, = (self.home / '.dotfiles_old').iterdir()
        self.assertEqual((backup / 'profile').read_text(), '# host profile\n')
        self.assertTrue((backup / 'bash-it-checkout/custom/host.bash').is_file())
        self.install()
        self.assertEqual(len(list((self.home / '.dotfiles_old').iterdir())), 1)

    def test_modified_checkout_is_not_overwritten(self):
        self.install()
        entry = self.repo / 'bash-it/bash_it.sh'
        entry.write_text('# local modification\n')
        result = self.install(check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('tracked local changes', result.stderr)
        self.assertEqual(entry.read_text(), '# local modification\n')

    def test_posix_environment_and_profile(self):
        (self.home / '.local/bin').mkdir(parents=True)
        (self.home / 'bin').mkdir()
        self.install()
        self.env['PATH'] = '/usr/bin:/bin'
        for shell in ('sh', 'bash', 'dash'):
            if not shutil.which(shell):
                continue
            self.run_cmd([shell, '-c', '. "$HOME/.shellenv"; first=$PATH; '
                          '. "$HOME/.shellenv"; test "$first" = "$PATH"'])
            self.run_cmd([shell, '-c', '. "$HOME/.profile"'])
