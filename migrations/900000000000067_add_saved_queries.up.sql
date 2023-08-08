BEGIN; 

INSERT INTO mergestat.saved_queries (created_by, name, description, sql)
VALUES 
(
    'postgres',
    'Cycle Time',
    'time from first commit is made to when the PR Is merged',
    'SELECT repos.id, github_pull_requests.head_repository_name,github_pull_request_commits.hash, github_pull_request_commits.pr_number, github_pull_request_commits.committer_when, github_pull_requests.merged_at,  
    EXTRACT(DAY FROM age(github_pull_requests.merged_at::timestamp, github_pull_request_commits.committer_when::timestamp)) AS days,
    EXTRACT(HOUR FROM age(github_pull_requests.merged_at::timestamp, github_pull_request_commits.committer_when::timestamp)) AS hours,
    EXTRACT(MINUTE FROM age(github_pull_requests.merged_at::timestamp, github_pull_request_commits.committer_when::timestamp)) AS minutes,
    EXTRACT(SECOND FROM age(github_pull_requests.merged_at::timestamp, github_pull_request_commits.committer_when::timestamp)) AS seconds
FROM repos
INNER JOIN github_pull_requests ON repos.id = github_pull_requests.repo_id
INNER JOIN github_pull_request_commits ON github_pull_requests.number = github_pull_request_commits.pr_number
WHERE github_pull_requests.merged is TRUE;'
), 

(
    'postgres',
    'PR Throughput',
    'number of merged PRs per engineer per week',
    'SELECT
    public.github_pull_requests.author_login,
    EXTRACT(YEAR FROM public.github_pull_requests.created_at) AS year_num,
    EXTRACT(WEEK FROM public.github_pull_requests.created_at) AS week_num,
    COUNT(*) AS total_pull_requests
FROM public.github_pull_requests
WHERE
    public.github_pull_requests.created_at IS NOT NULL and merged is TRUE
GROUP BY 1, 2, 3
ORDER BY 1,2 DESC, 3 DESC'
), 

(
    'postgres',
    'Commit Velocity',
    'number of non-merge commits per engineer per day',
    'SELECT
    public.git_commits.author_name,
    EXTRACT(YEAR FROM public.git_commits.author_when) AS year_num,    
    EXTRACT(DOY FROM public.git_commits.author_when) AS day_of_year_num,
    COUNT(*) AS total_commits
FROM public.git_commits
INNER JOIN public.repos ON public.git_commits.repo_id = public.repos.id
WHERE
    public.git_commits.committer_when IS NOT NULL
    AND public.git_commits.parents < 2 -- exclude merge commits
GROUP BY 1, 2, 3
ORDER BY 1, 2 DESC, 3 DESC'
), 

(
    'postgres',
    'Merge Time',
    'average time to merge a PR by engineer',
    'SELECT
    public.repos.repo,
    public.github_pull_requests.author_name,
    avg(extract(EPOCH FROM (public.github_pull_requests.merged_at - public.github_pull_requests.created_at)))::integer AS avg_seconds_to_merge,
    avg(extract(EPOCH FROM (public.github_pull_requests.merged_at - public.github_pull_requests.created_at))/60)::integer AS avg_minutes_to_merge,
    avg(extract(EPOCH FROM (public.github_pull_requests.merged_at - public.github_pull_requests.created_at))/60/60)::integer AS avg_hours_to_merge,
    avg(extract(EPOCH FROM (public.github_pull_requests.merged_at - public.github_pull_requests.created_at))/60/60/24)::integer AS avg_days_to_merge
FROM public.github_pull_requests
INNER JOIN public.repos ON public.github_pull_requests.repo_id = public.repos.id
WHERE public.github_pull_requests.merged_at IS NOT NULL
GROUP BY 1, 2
ORDER BY 3 DESC;'
), 

(
    'postgres',
    'Merge Trends',
    'evolution of average merging time',
    'SELECT
    public.repos.repo,
    EXTRACT(YEAR FROM public.github_pull_requests.merged_at) AS year_num,
    EXTRACT(WEEK FROM public.github_pull_requests.merged_at) AS week_num,
    ROUND(AVG(EXTRACT(DAY FROM age(github_pull_requests.merged_at::timestamp, github_pull_requests.created_at::timestamp)))) AS days,
    ROUND(AVG(EXTRACT(HOUR FROM age(github_pull_requests.merged_at::timestamp, github_pull_requests.created_at::timestamp)))) AS hours,
    ROUND(AVG(EXTRACT(MINUTE FROM age(github_pull_requests.merged_at::timestamp, github_pull_requests.created_at::timestamp)))) AS minutes,
    ROUND(AVG(EXTRACT(SECOND FROM age(github_pull_requests.merged_at::timestamp, github_pull_requests.created_at::timestamp)))) AS seconds
FROM public.github_pull_requests
INNER JOIN public.repos ON public.github_pull_requests.repo_id = public.repos.id
WHERE public.github_pull_requests.merged_at IS NOT NULL
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;
'
);

COMMIT;