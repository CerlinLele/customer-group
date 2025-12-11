# Glue Triggers disabled - manual job orchestration only

# Create scheduled triggers for jobs with explicit job-to-job dependencies
resource "aws_glue_trigger" "job_dependency_triggers" {
  for_each = {
    for job_name, job in local.jobs_map :
    job_name => job
    if length(lookup(job, "dependencies", [])) > 0 &&
    length([for dep in lookup(job, "dependencies", []) : dep if contains(keys(local.jobs_map), dep)]) > 0
  }

  name    = "${each.value.job_name}-trigger"
  type    = "CONDITIONAL"
  enabled = true

  actions {
    job_name = each.value.job_name
  }

  # Predicate: upstream job dependencies must succeed
  predicate {
    logical = "ANY"

    dynamic "conditions" {
      for_each = [for dep in lookup(each.value, "dependencies", []) : dep if contains(keys(local.jobs_map), dep)]

      content {
        job_name = conditions.value
        state    = "SUCCEEDED"
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${each.value.job_name}-trigger"
    }
  )

  depends_on = [aws_glue_job.jobs]
}
