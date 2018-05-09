require 'aws-sdk-ec2'
require 'graphviz'

ec2 = Aws::EC2::Client.new(region: 'us-east-1')
@key_for_group_name_to_id = {}
@security_groups_inbound_groups = {}

def describe_ip_permission(ip_permission,security_group_name)
  paired_ids = []
  if ip_permission.user_id_group_pairs.count > 0
    ip_permission.user_id_group_pairs.each do |user_id_group_pair|
      paired_ids << user_id_group_pair.group_id
    end
    @security_groups_inbound_groups[security_group_name] = paired_ids
  end
end

describe_security_groups_result = ec2.describe_security_groups
describe_security_groups_result.security_groups.each do |security_group|
  @key_for_group_name_to_id[security_group.group_id] = security_group.group_name
  if security_group.ip_permissions.count > 0
    security_group.ip_permissions.each do |ip_permission|
      describe_ip_permission(ip_permission,security_group.group_name)
    end
  end
end

puts @key_for_group_name_to_id
puts "**********************"
puts @security_groups_inbound_groups


g = GraphViz.new( :G, :type => :digraph )
@security_groups_inbound_groups.each do |destination, source_ids|
  if g.search_node(destination).nil?
    g.add_nodes(destination)
  end
  next if source_ids.nil?
  source_ids.each do |ingress_id|
    if g.search_node(@key_for_group_name_to_id[ingress_id]).nil?
      g.add_nodes(@key_for_group_name_to_id[ingress_id])
    end
    g.add_edges(@key_for_group_name_to_id[ingress_id],destination)
  end
  g.output( :png => "security_groups_connections.png" )
end
