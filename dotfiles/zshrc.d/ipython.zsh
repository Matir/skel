if command -v ipython >/dev/null || command -v ipython3 >/dev/null ; then
  export PYTHONSTARTUP="${HOME}/.ipython.py"
fi
