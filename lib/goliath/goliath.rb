module Goliath
  module_function

  @env = 'development'

  def env
    @env
  end

  def env=(env)
    case(env)
    when 'dev' then @env = 'development'
    when 'prod' then @env = 'production'
    when 'test' then @env = 'test'
    end
  end

  def prod?
    @env == 'production'
  end

  def dev?
    @env == 'development'
  end

  def test?
    @env == 'test'
  end
end