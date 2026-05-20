# Shared BuildInitialize hook for test projects.
#
# Sleeps for a random number of seconds (0-180) before the AL-Go pipeline
# starts pulling docker images, creating containers, compiling and running
# tests. The goal is to spread the load that many parallel test jobs put on
# GitHub-hosted resources (image registry, NuGet feeds, runners, test result
# uploads, etc.), reducing the rate of transient failures we see when many
# jobs hit those resources at the same instant.
#
# This script is invoked by AL-Go as the BuildInitialize hook (a single
# [Hashtable] $parameters argument is passed in by Invoke-ALGoHook).

$maxDelaySeconds = 180
$delaySeconds = Get-Random -Minimum 0 -Maximum ($maxDelaySeconds + 1)

Write-Host "BuildInitialize: sleeping $delaySeconds second(s) (random 0-$maxDelaySeconds) to spread parallel job load on GitHub."
Start-Sleep -Seconds $delaySeconds
