# setup pubsub topic and subscription for postgres
# define schema - if message formating is required.
resource "google_pubsub_schema" "schema" {
  count      = var.schema != null ? 1 : 0
  project    = var.project_id
  name       = var.schema.name
  type       = var.schema.type
  definition = var.schema.definition
}
# create topic - postgres-log-sink
resource "google_pubsub_topic" "postgres-log-sink" {
  count        = var.create_topic ? 1 : 0
  project      = var.project_id
  name         = var.topic
  labels       = var.topic_labels
  kms_key_name = var.topic_kms_key_name
  dynamic "message_storage_policy" {
    for_each = var.message_storage_policy
    content {
      allowed_persistence_regions = message_storage_policy.key == "allowed_persistence_regions" ? message_storage_policy.value : null
    }
  }
  dynamic "schema_settings" {
    for_each = var.schema != null ? [var.schema] : []
    content {
      schema   = google_pubsub_schema.schema[0].id
      encoding = lookup(schema_settings.value, "encoding", null)
    }
  }
  depends_on = [google_pubsub_schema.schema]
}
# create subscription - postgres-log-subscription
resource "google_pubsub_subscription" "postgres-log-subscription" {
  for_each = var.create_subscriptions ? { for i in var.pull_subscriptions : i.name => i } : {}
  name    = each.value.name
  topic   = google_pubsub_topic.postgres-log-sink.id
  project = var.project_id
  labels  = var.subscription_labels
  message_retention_duration = "86400s"
  depends_on = [
    google_pubsub_topic.postgres-log-sink
  ]
}

resource "google_pubsub_topic_iam_member" "postgres-log-writer" {
  project = var.project_id
  topic   = google_pubsub_topic.postgres-log-sink.id
  role    = "roles/pubsub.publisher"
  member  = [
    google_logging_organization_sink.postgres-sink.writer_identity,
  ]
  depends_on = [
    google_pubsub_topic.postgres-log-sink
  ]
}

resource "google_pubsub_subscription_iam_member" "postgres-log-subscription" {
  for_each = var.create_subscriptions ? { for i in var.pull_subscriptions : i.name => i } : {}
  project      = var.project_id
  subscription = each.value.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${var.impervasa}"
  depends_on = [
    google_pubsub_subscription.postgres-log-subscription
  ]
}
