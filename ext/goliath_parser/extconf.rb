require 'mkmf'

dir_config("goliath_parser")
have_library("c", "main")

create_makefile("goliath_parser")
