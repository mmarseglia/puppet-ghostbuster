require 'puppetdb'

class PuppetGhostbuster
  class PuppetDB

    def self.client
      @@client ||= ::PuppetDB::Client.new()
    end

    def client
      self.class.client
    end

    def self.classes
      @@classes ||= client.request('', 'resources[title] { type = "Class" and nodes { deactivated is null } }').data.map { |r| r['title'] }.uniq
    end

    def classes
      self.class.classes
    end

    def self.resources
      @@resources ||= client.request('', 'resources[type] { nodes { deactivated is null } }').data.map { |r| r['type'] }.uniq
    end

    def resources
      self.class.resources
    end
  end
end
