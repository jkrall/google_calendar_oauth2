module GoogleCalendar
  class Event
    attr_accessor :id, :summary, :description, :calendar_id, :start_time, :end_time, :sequence, :etag, :status, :html_link, :created_at, :updated_at

    extend Connection

    def initialize(attrs)
      @id = attrs['id']
      @etag = attrs['etag']
      @summary = attrs['summary']
      @description = attrs['description']
      @status = attrs['status']
      @html_link = attrs['htmlLink']
      @created_at = attrs['created']
      @updated_at = attrs['updated']
      @calendar_id = attrs['calendar_id']
      @sequence = attrs['sequence']
      @start_time = attrs['start']['dateTime']
      @end_time = attrs['end']['dateTime']
    end

    alias attributes= initialize

    def to_s
      "#<GoogleCalendar::Event #{attributes.inspect}>"
    end

    def attributes
      {
        id: id,
        etag: etag,
        summary: summary,
        description: description,
        status: status,
        html_link: html_link,
        created_at: created_at,
        updated_at: updated_at,
        calendar_id: calendar_id,
        sequence: sequence,
        start: {
          :dateTime => start_time
        },
        end: {
          :dateTime => end_time
        }
      }
    end

    def self.list(calendar_id, query = nil)
      params = { 'calendarId' => calendar_id }
      params['q'] = query if query
      list = connection.execute(api_method: client.events.list, parameters: params)
      events = []
      list.data.items.each do |event|
        events << new(event.to_hash.merge({ 'calendar_id' => calendar_id }))
      end
      events
    end

    def self.find_by_name(calendar_id, query)
      list(calendar_id, query).each do |event|
        if event.summary == query
          return @event = new(event.attributes.merge({ 'calendar_id' => calendar_id }))
        end
      end
      @event
    end

    def self.find_by_id(calendar_id, id)
      event = connection.execute(
        api_method: client.events.get,
        parameters: {
          'calendarId' => calendar_id,
          'eventId' => id
        }
      )
      new event.data.to_hash.merge 'calendar_id' => calendar_id
    end

    def self.insert(calendar_id, attrs)
      new connection.execute(
        api_method: Event.client.events.insert,
        parameters: { 'calendarId' => calendar_id },
        body: JSON.dump(attrs),
        headers: {'Content-Type' => 'application/json'}
      ).data.to_hash.merge 'calendar_id' => calendar_id
    end
    def self.create(calendar_id, attrs); insert(calendar_id, attrs) end

    def update(attrs = {})
      self.sequence = self.sequence.nil? ? 1 : self.sequence + 1
      attrs = self.attributes.stringify_keys.merge(attrs.stringify_keys)
      result = Event.connection.execute(
        api_method: Event.client.events.update,
        parameters: {
          'calendarId' => self.calendar_id,
          'eventId' => self.id
        },
        body: JSON.dump(attrs),
        headers: {'Content-Type' => 'application/json'}
      ).data.to_hash.merge('calendar_id' => self.calendar_id)
      self.attributes = result
      self
    end

    def self.delete(calendar_id, event_id)
      connection.execute(
        api_method: client.events.delete,
        parameters: {
          'calendarId' => calendar_id,
          'eventId' => event_id
        }
      )
    end
  end
end