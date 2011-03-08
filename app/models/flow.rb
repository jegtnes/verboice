class Flow
  def initialize(context)
    @context = context
  end

  def run(commands)
    commands.each do |cmd|
      if cmd.is_a? Hash
        cmd, args = cmd.first
        cmd = "#{cmd.to_s.camelcase}Command".constantize.new args
      else
        cmd = "#{cmd.to_s.camelcase}Command".constantize.new
      end

      cmd.run @context
    end
  end
end