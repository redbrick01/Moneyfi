select cron.alter_job(job_id := jobid, schedule := '* * * * *')
from cron.job
where jobname = 'update-holding-prices-every-10-min';
