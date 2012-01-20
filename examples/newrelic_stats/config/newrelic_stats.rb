# Manually start the New Relic agent

# NOTE: this will also automatically create a 'logs' directory in your app root
# if it does not already exist. Check this directory for New Relic Agent logs if you
# are encountering startup issues.

NewRelic::Agent.manual_start({:env => Goliath.env.to_s})
