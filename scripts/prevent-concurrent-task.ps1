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

# Load the MySQL .NET Connector assembly
[void][system.reflection.Assembly]::LoadFrom("C:\Program Files (x86)\MySQL\MySQL Connector NET 9.0\MySql.Data.dll")

# Connection string
$connectionString = "server=$SystemDBAddress;user=$SystemDBUsername;database=$SystemDBDatabase;port=3306;password=$SystemDBPassword;"

# Function to execute a SELECT query
function Execute-MySQLQuery {
    param (
        [string]$query
    )
    try {
        # Create a new MySQL connection
        $connection = New-Object MySql.Data.MySqlClient.MySqlConnection($connectionString)
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

# Function to execute a non-query (e.g., INSERT)
function Execute-MySQLNonQuery {
    param (
        [string]$query
    )
    try {
        # Create a new MySQL connection
        $connection = New-Object MySql.Data.MySqlClient.MySqlConnection($connectionString)
        $connection.Open()

        # Create the command and execute the query
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
        $recordsFound = Execute-MySQLQuery -query $selectQuery

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
        Execute-MySQLNonQuery -query $insertQuery
        Write-Host "No active release found, continuing"
    }
    "done" {
        $insertQuery = "DELETE FROM active_release WHERE parent_project = '$ParentProjectName' AND project = '$ProjectName' AND environment = '$Environment';"
        Write-Host "Finished release operation."
        Execute-MySQLNonQuery -query $insertQuery
    }
    default {
        Write-Host "Invalid operation. Please enter 'check' or 'save'."
    }
}