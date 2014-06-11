Totals = Struct.new(:completed, :started, :processing, :failures) do
  def self.create
     self.new 0, 0, 0, 0
  end
  members.each do | member |
    self.class_eval %Q{
      def #{member}!(count=1)
        self.#{member}+=count
        self
      end
    }
  end
end



class Buckets

  MINUTE_GRANULARITY = 5

  def initialize
    @storage = Hash.new{ | h, segment | h[segment] = Totals.create }
  end

  def record(job)

    if job.complete?
      record = at(job.updated_at).completed!
      record.failures! if job.failed?
    end
    at(job.created_at).started!

    # increment the processing count for all periods that the job was processing
    between( job.created_at, job.updated_at ) do | bucket |
      bucket.processing!
    end
  end

  def between( start_time, end_time )
    (start_time.to_i..end_time.to_i).step(60*MINUTE_GRANULARITY).each do | ts |
      yield at(Time.at(ts))
    end
  end

  def at(time)
p time
    # Returns a integer version of year, month, day, and 5 minute segment number
    # i.e. 4:39 pm on 2014-06-09 will round down to nearest 5 minute segment, i.e. 2014060935
    ts = sprintf("%s%02d", time.strftime('%Y%m%d%H'), time.min.divmod( MINUTE_GRANULARITY ).first * MINUTE_GRANULARITY ).to_i
    @storage[ts]
  end

  def to_hash
    @storage
  end

end