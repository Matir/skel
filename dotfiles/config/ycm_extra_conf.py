def Settings( **kwargs ):
  client_data = kwargs[ 'client_data' ]
  return {
    'interpreter_path': client_data[ 'g:ycm_python_interpreter_path' ] or '/usr/bin/python3',
    'sys_path': client_data[ 'g:ycm_python_sys_path' ]
  }
