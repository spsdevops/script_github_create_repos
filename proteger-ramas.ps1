# Lee el archivo CSV
Import-Csv ".\crear-repos.csv" |
    # Por cada fila del archivo
    ForEach-Object {
        # Extraer valores
        $Organizacion = $_.organizacion
        $Repositorio = $_.repositorio
 
        # Muestra repositorio a proteger
        Write-Host "------- " "$Organizacion/$Repositorio" "----------"
        
        Write-Host " > protegiendo ramas"
        $response = gh api repos/$Organizacion/$Repositorio --jq .node_id
        Write-Host "    * ID repo: $response"


        gh api graphql -f query='
        mutation($repositoryId:ID!,$branch:String!) {
          createBranchProtectionRule(input: {
            repositoryId: $repositoryId
            pattern: $branch
          }) { clientMutationId }
        }' -f repositoryId="$response" -f branch="releases/*"
    }
