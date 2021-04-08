#! /usr/bin/env python


import os, time, tempfile, json
from datadog import initialize, api



TMP_REPORT = tempfile.NamedTemporaryFile().name
GITHUB_REPOSITORY = os.getenv('GITHUB_REPOSITORY')
DD_CLIENT_API_KEY = os.getenv('DD_CLIENT_API_KEY')
PROJECT_FOLDER = "./"




def execute_sast():
    report = {}
    cmd_bandit = "bandit -r -a vuln -ii -ll -x .git,.svn,.mvn,.idea,dist,bin,obj,backup,docs,tests,test,tmp,reports,venv {0} -f json -o {1} --exit-zero".format(PROJECT_FOLDER,TMP_REPORT)
    cmd_cat = "cat {0}".format(TMP_REPORT)
    os.system('bandit --version')
    print(cmd_bandit)
    os.system(cmd_bandit)
    os.system(cmd_cat)

    with open(TMP_REPORT) as f:
        report = json.load(f)
    
    return report




def send_metrics(vulns=[]):
    now = time.time()

    options = {
        'api_key': DD_CLIENT_API_KEY
    }
    initialize(**options)

    for v in vulns:
        api.Metric.send(
            metric='security.sast.results',
            points=[
                (now, 1)
            ],
            tags=[
                "repo:" + v['repository_name'],
                "test_id:" + v['test_id'],
                "test_name:" + v['test_name'],
                "issue_text:" + v['issue_text'],
                "filename:" + v['filename'],
                "issue_severity:" + v['issue_severity'],
                "line_number:" + v['line_number']
            ]
        )
    
    return




def parse_results(raw):
    dd_tag_limit = 199
    tags = {}
    vulns = []

    if raw['results']:
        for r in raw['results']:
            if r['issue_severity'] == 'HIGH' or 'MEDIUM':
                tags['repository_name'] = GITHUB_REPOSITORY
                tags['test_id'] = r['test_id']
                tags['test_name'] = r['test_name']
                tags['issue_text'] = r['issue_text'][:dd_tag_limit]
                tags['filename'] = r['filename'][:dd_tag_limit]
                tags['issue_severity'] = r['issue_severity']
                tags['line_number'] = str(r['line_number'])
                tags_copy = tags.copy()
                vulns.append(tags_copy)
    else:
        print("Great, no findings!")
    
    send_metrics(vulns)
    vulns.clear()

    return




def main():
    #raw_report = execute_sast()
    #parse_results(raw_report)
    print(os.getenv('GITHUB_SERVER_URL'))
    print(os.getenv('GITHUB_WORKSPACE'))
    print(os.getenv('GITHUB_ACTOR'))




if __name__ == "__main__":
    main()
