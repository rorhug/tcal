class IndexQueJobArg0 < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      dir.up do
        execute("CREATE INDEX que_jobs_args_0 ON que_jobs ((args->>0));")
      end
      dir.down do
        execute("DROP INDEX que_jobs_args_0;")
      end
    end
  end
end
