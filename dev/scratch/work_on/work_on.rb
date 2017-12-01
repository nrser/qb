

# @todo Document work_on method.
# 
# @param [type] arg_name
#   @todo Add name param description.
# 
# @return [return_type]
#   @todo Document return value.
# 
def work_on_issue number, service
  
  issue = repo.issue number
  
  branch_name = "issue-#{ issue.number }"
  dir_name = "#{ issue.number }_#{ issue.filename }"
  
  repo.be_on_branch branch_name, from: :master
  
  path = if issue.milestone
    service.tests_path / "milestones" / "#{ issue.milestone.number }_#{ issue.milestone. }" / dir_name
  else
    service.tests_path / 
  
end # #work_on_issue

