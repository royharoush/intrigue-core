module Intrigue
  module Model
    class TaskResult

      attr_accessor :id, :name, :timestamp_start, :timestamp_end
      attr_accessor :options, :entity, :task_name, :entities, :log
      attr_accessor :complete

      def self.key
        "task_result"
      end

      def key
        "#{Intrigue::Model::TaskResult.key}"
      end

      def initialize(id,name)
        @id = id
        @name = name
        @lookup_key = "#{key}:#{@id}"
        @timestamp_start = DateTime.now
        @timestamp_end = DateTime.now
        @entity = nil
        @task_name = nil
        @options = []
        @entities = []
        @complete = false
        @log = TaskResultLog.new(id, name); @log.save # save must be called to persist objects
      end

      def entities
        @entities
      end

      def self.find(id)
        lookup_key = "#{key}:#{id}"
        result = $intrigue_redis.get(lookup_key)
        raise "Unable to find #{lookup_key}" unless result

        s = TaskResult.new("nope","nope")
        s.from_json(result)
        s.save

        # if we didn't find anything in the db, return nil
        return nil if s.name == "nope"
      s
      end

      def add_entity(entity)
        @entities << entity
        save
      end

      def from_json(json)
        begin
          x = JSON.parse(json)
          @id = x["id"]
          @name = x["name"]
          @task_ids = x["task_ids"]
          @timestamp_start = x["timestamp_start"]
          @timestamp_end = x["timestamp_end"]
          @entity = Entity.find x["entity_id"]
          @task_name = x["task_name"]
          @options = x["options"]
          @entities = x["entity_ids"].map { |y| Entity.find y }
          @complete = x["complete"]
          @log = TaskResultLog.find x["id"]
        rescue JSON::ParserError => e
          return nil
        end
      end

      def to_json
        {
          "id" => @id,
          "name" => @name,
          "task_name" => @task_name,
          "timestamp_start" => @timestamp_start,
          "timestamp_end" => @timestamp_end,
          "entity_id" => @entity.id,
          "options" => @options,
          "complete" => @complete,
          "entity_ids" => @entities.map{ |x| x.id }
        }.to_json
      end

      def to_s
        to_json
      end

      def save
        lookup_key = "#{key}:#{@id}"
        $intrigue_redis.set lookup_key, to_json
      end

    end
  end
end