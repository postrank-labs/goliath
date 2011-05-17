module Goliath
  # Constants used by the system to access data.
  module Constants
    INITIAL_BODY = ''
    # Force external_encoding of request's body to ASCII_8BIT
    INITIAL_BODY.encode!(Encoding::ASCII_8BIT) if INITIAL_BODY.respond_to?(:encode)

    SERVER_SOFTWARE = 'SERVER_SOFTWARE'
    SERVER          = 'Goliath'

    HTTP_PREFIX     = 'HTTP_'
    LOCALHOST       = 'localhost'
    STATUS          = 'status'
    CONFIG          = 'config'
    OPTIONS         = 'options'

    RACK_INPUT      = 'rack.input'
    RACK_VERSION    = 'rack.version'
    RACK_ERRORS     = 'rack.errors'
    RACK_MULTITHREAD = 'rack.multithread'
    RACK_MULTIPROCESS = 'rack.multiprocess'
    RACK_RUN_ONCE   = 'rack.run_once'
    RACK_VERSION_NUM = [1, 0]
    RACK_LOGGER     = 'rack.logger'
    RACK_EXCEPTION  = 'rack.exception'

    ASYNC_CALLBACK  = 'async.callback'
    ASYNC_HEADERS   = 'async.headers'
    ASYNC_BODY      = 'async.body'
    ASYNC_CLOSE     = 'async.close'

    STREAM_START    = 'stream.start'
    STREAM_SEND     = 'stream.send'
    STREAM_CLOSE    = 'stream.close'

    SERVER_NAME     = 'SERVER_NAME'
    SERVER_PORT     = 'SERVER_PORT'
    SCRIPT_NAME     = 'SCRIPT_NAME'
    REMOTE_ADDR     = 'REMOTE_ADDR'
    CONTENT_LENGTH  = 'CONTENT_LENGTH'
    CONTENT_TYPE    = 'CONTENT_TYPE'
    REQUEST_METHOD  = 'REQUEST_METHOD'
    REQUEST_URI     = 'REQUEST_URI'
    QUERY_STRING    = 'QUERY_STRING'
    HTTP_VERSION    = 'HTTP_VERSION'
    REQUEST_PATH    = 'REQUEST_PATH'
    PATH_INFO       = 'PATH_INFO'
    FRAGMENT        = 'FRAGMENT'
    CONNECTION      = 'CONNECTION'

    GOLIATH_ENV     = 'goliath.env'
  end
end
