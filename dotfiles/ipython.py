try:
    import os, IPython
    from traitlets import config
    os.environ['PYTHONSTARTUP'] = ''  # Prevent running this again
    cfg = config.Config()
    cfg.TerminalIPythonApp.display_banner = False
    IPython.start_ipython(config=cfg)
    raise SystemExit
except ImportError:
    pass
