# 직급(팀장·매니저). 하는 일을 적는 직함(job_title)과는 따로 둔다.
class AddJobRankToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :job_rank, :string
  end
end
