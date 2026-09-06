# Snyk and SonarQube

Both tools are implementation of SAST concept aka White Box Testing.

## [Snyk](https://snyk.io/) and CI/CD tool integration - ex. GitHub
### Integration
- Just simply add this job to ```.github/workflows/<<name_for_ci_cd>>.yaml```. Example for [Golang](https://github.com/snyk/actions/tree/master/golang) based project:
```yaml
  security:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Run Snyk to check for vulnerabilities
        uses: snyk/actions/golang@master
        continue-on-error: true # Ensure SARIF upload is executed
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --sarif-file-output=snyk.sarif

      - name: Upload Snyk results to GitHub Code Scanning
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: snyk.sarif
```
- Integrated results can be found at route:
```
<<repo_name>> => Security => Code scanning alerts
```
![scan_result](https://raw.githubusercontent.com/snyk/actions/refs/heads/master/_templates/sarif-example.png)

- Snyk actions repository can be found here for other types of project: https://github.com/snyk/actions/tree/master

### [**SARIF (Static Analysis Results Interchange Format)**](https://sarifweb.azurewebsites.net/)
- Github code scans can only be perfomred by third-party software that outputs in **SARIF**. Code scans and SARIF documentation can be found here:
    + https://docs.github.com/en/code-security/code-scanning/introduction-to-code-scanning/about-code-scanning
    + https://docs.github.com/en/code-security/code-scanning/integrating-with-code-scanning/sarif-support-for-code-scanning

> Unfortunately integration with CI/CD and Git repositories is now ONLY offered as paid plan.

### Sample outputs from Snyk https://app.snyk.io/
- Scans can be performed directly at third-party software provider, in that case Snyk. 
- Integrating Snyk with Github is essential. Go to: ```Organization => Projects => View all your repositories => (pick repository of your choice) => Add selected repository```.
- By default only public repositories can be scanned, also prolly depends on what version of Github have you integrated (Github VS Github Enterprise etc). 
Free tier offers scans for public repos only (??? not sure).
- Initial scan will be performed automatically. 
- Go to: ```Organization => Projects => (check scan for previously picked repo)```.
- Sample output: 
![SampleSnykScan.png](/xyz_resources_n_images/SampleSnykScan.png)
- After clicking at any of those submodels views moe insights and possible vulnerability solving ideas.

## SonarQube quick sum-up


## Useful links:
### Snyk
- https://github.com/snyk/actions/tree/master/golang
- https://www.youtube.com/watch?v=5bGySX6zup8&ab_channel=KnowledgeAmplifier

### SonarQube
- https://docs.sonarsource.com/sonarqube-server/10.6/devops-platform-integration/github-integration/introduction/