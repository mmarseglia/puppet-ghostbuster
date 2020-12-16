PuppetLint.new_check(:ghostbuster_templates) do
  def manifests
    Dir.glob('./**/manifests/**/*.pp')
  end

  def templates
    Dir.glob('./**/templates/**/*').select{ |f| File.file? f }
  end

  def check
    m = path.match(%r{.*/([^/]+)/templates/(.+)$})
    return if m.nil?

    module_name, template_name = m.captures

    manifests.each do |manifest|
      return if File.readlines(manifest).grep(%r{["']#{module_name}/#{template_name}["']}).size > 0
      if match = manifest.match(%r{.*/([^/]+)/manifests/.+$})
        if match.captures[0] == module_name
          return if File.readlines(manifest).grep(/["']\$\{module_name\}\/#{template_name}["']/).size > 0
        end
      end
    end

    templates.each do |template|
      return if File.readlines(template).grep(%r{scope.function_template\(\['#{module_name}/#{template_name}'\]\)}).size > 0
    end

    notify :warning, {
      :message => "Template #{module_name}/#{template_name} seems unused",
      :line    => 1,
      :column  => 1,
    }
  end
end
