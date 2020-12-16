require 'puppet-ghostbuster/puppetdb'

PuppetLint.new_check(:ghostbuster_files) do
  def manifests
    Dir.glob('./**/manifests/**/*.pp')
  end

  def check
    m = path.match(%r{.*/([^/]+)/files/(.+)$})
    return if m.nil?

    puppetdb = PuppetGhostbuster::PuppetDB.new

    module_name, file_name = m.captures
    query = "resources[title] { parameters.source = 'puppet:///modules/#{module_name}/#{file_name}' and nodes { deactivated is null } }"
    return if puppetdb.client.request('', query).data.size > 0

    dir_name = File.dirname(file_name)
    while dir_name != '.' do
      query = "resources[title] {
        (parameters.source = 'puppet:///modules/#{module_name}/#{dir_name}'
         or parameters.source = 'puppet:///modules/#{module_name}/#{dir_name}/')
        and parameters.recurse = true
        and nodes { deactivated is null } }"
      return if puppetdb.client.request('', query).data.size > 0
      dir_name = File.dirname(dir_name)
    end

    manifests.each do |manifest|
      return if File.readlines(manifest).grep(%r{["']#{module_name}/#{file_name}["']}).size > 0
      if match = manifest.match(%r{.*/([^/]+)/manifests/.+$})
        if match.captures[0] == module_name
          return if File.readlines(manifest).grep(/["']\$\{module_name\}\/#{file_name}["']/).size > 0
        end
      end
    end

    notify :warning, {
      :message => "File #{module_name}/#{file_name} seems unused",
      :line    => 1,
      :column  => 1,
    }
  end
end
