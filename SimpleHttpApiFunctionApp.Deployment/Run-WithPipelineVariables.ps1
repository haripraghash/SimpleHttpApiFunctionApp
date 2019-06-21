param(
	[string]$ScriptPath,
	[hashtable]$secretVariables
)

Set-Location $PSScriptRoot

$rawParams = @{}
$params = @{}

# Add all environment variables to the parameters hashtable
$envs = (Get-ChildItem env:)

foreach ($env in $envs)
{
	$bool = $null
	if ([bool]::TryParse($env.Value, [ref] $bool))
	{ 
		$rawParams[$env.Name] = $bool 
	}
	else 
	{
		$rawParams[$env.Name] = $env.Value 
	}
}

# Add all secret variables to the parameters hashtable
$secretVariables.GetEnumerator() | Foreach-Object { $rawParams[$_.Name] = (convertto-securestring $_.Value -asplaintext -force) }

# Strip the parameters hashtable down to the required set of parameters for the script
$scriptParameters = (Get-Command $ScriptPath).Parameters.GetEnumerator() | Select Key
$rawParams.GetEnumerator() | Foreach-Object { if ($scriptParameters.Key -contains $_.Name) { $params.Add($_.Name, $_.Value) } }

Write-Host ($params | Out-String)

& $ScriptPath @params