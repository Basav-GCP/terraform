resource "google_logging_organization_sink" "postgres-sink" {
  name   = "postgres-sink"
  description = "The sink for postgres logs for the prod folder for dbai"
  org_id = "251485126955"
  # folder name
  # folder = google_folder.prod-folder.name
  # Can export to pubsub, cloud storage, or bigquery
  destination = "google_pubsub_topic.postgres-log-sink.id"
  include_children = true
  # Log all WARN or higher severity messages relating to instances
  filter = "resource.type = gce_instance AND severity >= WARNING"
}
