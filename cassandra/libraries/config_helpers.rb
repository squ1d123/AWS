
require 'yaml'

def cassandra_yaml_config(c)
  config = JSON.parse(c.to_hash.dup.to_json)
  config.each do |k, v|
    config.delete(k) if k.nil? || v.nil?
  end  

  # remove eval attributes
  config['client_encryption_options'].delete('enable_advanced') # if config.key?('client_encryption_options')
  config['server_encryption_options'].delete('enable_advanced') # if config.key?('server_encryption_options')

  # delete num_tokens if vnodes is not set
  config.delete('num_tokens') unless node['cassandra']['vnodes']
  # delete initial_token if vnodes is set
  config.delete('initial_token') if node['cassandra']['vnodes']
  # remove row_cache_provider if row_cache_provider == SerializingCacheProvider
  config.delete('row_cache_provider') if config.key?('row_cache_provider') && config['row_cache_provider'] == 'SerializingCacheProvider'
  # remove commitlog_sync_period_in_ms if commitlog_sync_batch_window_in_ms is not set
  config.delete('commitlog_sync_period_in_ms') unless config.key?('commitlog_sync_batch_window_in_ms')
  # remove commitlog_sync_period_in_ms if commitlog_sync != periodic
  config.delete('commitlog_sync_period_in_ms') if config.key?('commitlog_sync') && config['commitlog_sync'] != 'periodic'
  # remove commitlog_sync_batch_window_in_ms if commitlog_sync == periodic
  config.delete('commitlog_sync_batch_window_in_ms') if config.key?('commitlog_sync') && config['commitlog_sync'] == 'periodic'

  config['start_rpc'] = cassandra_bool_config(config['start_rpc'])
  config['rpc_keepalive'] = cassandra_bool_config(config['rpc_keepalive'])
  Hash[config.sort].to_yaml
end

def cassandra_bool_config(config_val)
  if config_val.is_a?(String)
    config_val
  else
    if config_val
      'true'
    else
      'false'
    end
  end
end

def hash_to_yaml_string(hash)
  hash.to_hash.to_yaml
end


def discover_seed_nodes
  # use chef search for seed nodes
  if node['cassandra']['seed_discovery']['use_chef_search']
    if Chef::Config[:solo]
      Chef::Log.warn("Chef Solo does not support search, provide the seed nodes via node attribute node['cassandra']['seeds']")
      node['ipaddress']
    else
      Chef::Log.info('Cassandra seed discovery using Chef search is enabled')
      q = node['cassandra']['seed_discovery']['search_query'] ||
          "chef_environment:#{node.chef_environment} "\
          "AND role:#{node['cassandra']['seed_discovery']['search_role']} "\
          "AND cassandra_config_cluster_name:#{node['cassandra']['config']['cluster_name']}"
      Chef::Log.info("Will discover Cassandra seeds using query '#{q}'")
      xs = search(:node, q).map(&:ipaddress).sort.uniq
      Chef::Log.debug("Discovered #{xs.size} Cassandra seeds using query '#{q}'")

      if xs.empty?
        node['ipaddress']
      else
        xs.take(node['cassandra']['seed_discovery']['count']).join(',')
      end
    end
  else
    # user defined seed nodes
    if node['cassandra']['seeds'].is_a?(Array)
      node['cassandra']['seeds'].join(',')
    else
      node['cassandra']['seeds']
    end
  end
end
   
