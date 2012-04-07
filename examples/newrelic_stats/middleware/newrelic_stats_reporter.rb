module Examples
  module Rack
    class NewrelicStatsReporter

    # note: should probably add traces to this middleware, but deviation is very minimal even without
    include Goliath::Rack::AsyncMiddleware

      def post_process(env, status, headers, body)
        env.trace("NewrelicStatsReporter#post_process")

        stats = env.trace_stats

        # give this request a unique id so it can be differentiated in New Relic
        sig = Digest::SHA1.hexdigest(stats.to_s + Time.new.to_s)[8..16]
        env.logger.info("request id: #{sig}")

        scope = "Controller/Request/#{sig}"
        unscoped = NewRelic::Agent.agent.stats_engine.get_stats_no_scope(scope)
        data_to_merge = {}

        stats.each do |key, val|
          dp = val.to_f / 1000
          if key != "total"
            metric_name = "OtherTransaction/_/#{key}"
            metric_spec = NewRelic::MetricSpec.new(metric_name, scope)

            scoped = NewRelic::ScopedMethodTraceStats.new(unscoped)
            scoped.record_data_point(dp)

            metric_data = NewRelic::MetricData.new(metric_spec, scoped, nil)
            data_to_merge[metric_spec] = metric_data

          else

            # this will always be the last key that is processed.
            NewRelic::Agent.agent.stats_engine.get_stats_no_scope('HttpDispatcher').record_data_point(dp)
            unscoped.record_data_point(dp, 0)

            NewRelic::Agent.instance.stats_engine.merge_data(data_to_merge)

          end
        end

        [status, headers, body]
      end

    end

  end
end