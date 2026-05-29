CREATE SUBSCRIPTION player_scores_subscription
CONNECTION 'host=primary port=5432 dbname=replication_demo user=replicator password=replicator'
PUBLICATION player_scores_publication
WITH (copy_data = true);
