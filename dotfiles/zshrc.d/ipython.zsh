if have_command ipython || have_command ipython3 ; then
  export PYTHONSTARTUP="${HOME}/.ipython.py"
fi
