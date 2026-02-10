import os
import sys
from IPython import prompts

def _setup_environment():
    ip = get_ipython()
    if not ip:
        return

    # 1. SEARCH LOGIC: Walk up the tree for a venv
    active_venv_name = None
    curr = os.getcwd()

    while True:
        for venv_name in ['.venv', 'env', 'venv']:
            venv_path = os.path.join(curr, venv_name)
            if os.path.isdir(venv_path):
                # Platform-specific site-packages path
                py_ver = f"python{sys.version_info.major}.{sys.version_info.minor}"
                site_pkgs = os.path.join(venv_path, 'lib', py_ver, 'site-packages')

                if os.path.exists(site_pkgs):
                    if site_pkgs not in sys.path:
                        sys.path.insert(0, site_pkgs)
                        sys.prefix = venv_path
                    active_venv_name = os.path.basename(venv_path)
                    break

        if active_venv_name or os.path.exists(os.path.join(curr, '.git')):
            break

        parent = os.path.dirname(curr)
        if parent == curr:
            break
        curr = parent

    # 2. PROMPT LOGIC: Inject venv name into the UI
    class VenvPrompts(prompts.Prompts):
        def in_prompt_tokens(self):
            tokens = []
            if active_venv_name:
                tokens.append((prompts.Token.Prompt, f'({active_venv_name}) '))

            tokens.extend([
                (prompts.Token.Prompt, 'In ['),
                (prompts.Token.PromptNum, str(self.shell.execution_count)),
                (prompts.Token.Prompt, ']: '),
            ])
            return tokens

    ip.prompts = VenvPrompts(ip)

# Execute the setup
_setup_environment()

# cleanup
del _setup_environment, prompts
