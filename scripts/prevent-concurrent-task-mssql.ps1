param (
    [string]$SystemDBAddress,
    [string]$SystemDBDatabase,
    [string]$SystemDBUsername,
    [string]$SystemDBPassword,

    [string]$Operation,
    [string]$ProjectName,
    [string]$ParentProjectName,
    [string]$Environment
)

# Load the SQL Server .NET Connector assembly
[void][system.reflection.Assembly]::LoadWithPartialName("System.Data.SqlClient")

# Connection string for SQL Server
$connectionString = "Server=$SystemDBAddress;Database=$SystemDBDatabase;User Id=$SystemDBUsername;Password=$SystemDBPassword;"

# Function to execute a SELECT query
function Execute-MSSQLQuery {
    param (
        [string]$query
    )
    try {
        # Create a new SQL Server connection
        $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
        $connection.Open()

        # Create the command and execute the query
        $command = $connection.CreateCommand()
        $command.CommandText = $query
        $reader = $command.ExecuteReader()

        $hasRow = $reader.HasRows

        # Close connection
        $reader.Close()
        $connection.Close()

        return $hasRow
    } catch {
        Write-Error "An error occurred: $_"
    }
}

# Function to execute a non-query (e.g., INSERT or DELETE)
function Execute-MSSQLNonQuery {
    param (
        [string]$query
    )
    try {
        # Create a new SQL Server connection
        $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
        $connection.Open()

        # Create the command and execute the non-query
        $command = $connection.CreateCommand()
        $command.CommandText = $query
        $result = $command.ExecuteNonQuery()

        # Close connection
        $connection.Close()
    } catch {
        Write-Error "An error occurred: $_"
    }
}

# Function to run continuously until no records are found
function Run-UntilNoRecords {
    param (
        [string]$query,
        [int]$sleepDuration = 10  # Sleep for 10 seconds between checks
    )

    while ($true) {
        # Run the SELECT query and check if records are found
        $recordsFound = Execute-MSSQLQuery -query $query

        if ($recordsFound) {
            Write-Host "There is an active running job, waiting ..."
            Start-Sleep -Seconds $sleepDuration
            continue
        }

        break
    }
}

switch ($Operation) {
    "check" {
        # Perform a SELECT query
        $selectQuery = "SELECT * FROM active_release WHERE parent_project = '$ParentProjectName' AND project = '$ProjectName' AND environment = '$Environment';"
        Write-Host "Checking active release for this project."
        Run-UntilNoRecords -query $selectQuery -sleepDuration 10

        $insertQuery = "INSERT INTO active_release (parent_project, project, environment) VALUES ('$ParentProjectName', '$ProjectName', '$Environment');"
        Execute-MSSQLNonQuery -query $insertQuery
        Write-Host "No active release found, continuing"
    }
    "done" {
        $deleteQuery = "DELETE FROM active_release WHERE parent_project = '$ParentProjectName' AND project = '$ProjectName' AND environment = '$Environment';"
        Write-Host "Finished release operation."
        Execute-MSSQLNonQuery -query $deleteQuery
    }
    default {
        Write-Host "Invalid operation. Please enter 'check' or 'done'."
    }
}