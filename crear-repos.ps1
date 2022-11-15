# Parametros
param ([switch] $Debug)

#Crea archivo de reporte
$Timestamp = get-date -f yyyyMMddTHHmmssZ
$newcsv = {} | Select "repositorio", "url", "error" | Export-Csv -NoTypeInformation -Path ".\reporte_$Timestamp.csv" 
$salida = 0
# Lee el archivo CSV
Import-Csv ".\crear-repos.csv" |
    # Por cada fila del archivo
    ForEach-Object {
        # Extraer valores
        $Organizacion = $_.organizacion
        $Repositorio = $_.repositorio
        $Tipo = $_.tipo
        $Descripcion = $_.descripcion
        $AdminList = $_.admin_list
        $WriteList = $_.write_list
        $ReadList = $_.read_list
        $AprobadorPreList = $_.aprobador_pre_list
        $AprobadorProdList = $_.aprobador_prod_list

        # Variables Reporte
        $ReporteUrl = ""
        $ReporteError = ""

        # Muestra repositorio a crear y configurar
        Write-Host "------- " "$Organizacion/$Repositorio" "----------"
        
        # Crear repositorio con descripción y tipo (internal o private)
        Write-Host " > Creando repositorio"
        
        $response = gh repo create $Organizacion/$Repositorio -d `'$Descripcion`' --$Tipo
        $salida = $LASTEXITCODE
        if ($salida -eq 0) {
            $ReporteUrl = $response
        }
        if ($debug) {
            Write-Host $response
        }                
        if ($salida -ne 0) {
            Write-Host ">> El repositorio ya existe"
            $response = gh api -X GET /repos/$Organizacion/$Repositorio --jq .html_url
            $salida = $LASTEXITCODE
            Write-Host "   - $response"
            if ($salida -eq 0){
                Write-Host $response
                $ReporteUrl = $response
            } else {
                Write-Host ">> No se pudo obtener la URL"
                $ReporteError = "$ReporteError &No se pudo obtener la URL"
            }
        }

        
        # Agregar equipo como administrador, si es más de uno están separados por un &
        Write-Host " > Agregando equipos administradores"
        
        $AdminList -Split "&" |
        ForEach-Object {
            $Team = $_
            Write-Host "   -$Team" 
            $response = gh api -X PUT orgs/$Organizacion/teams/$Team/repos/$Organizacion/$Repositorio -f permission='admin'
            $salida = $LASTEXITCODE
            if ($debug) {
                Write-Host $response
            }
            if ($salida -ne 0) {
                Write-Host "No se pudo configurar a los administradores $Team"
                $ReporteError = "$ReporteError &No se pudo configurar a los administradores $Team"
            }
        }            

        # Agregar equipo con permisos de escritura, si es más de uno están separados por un &
        Write-Host " > Agregando equipos con permisos de escritura (push)"
        
        $WriteList -Split "&" |
        ForEach-Object {
            $Team = $_
            Write-Host "   -$Team" 
            $response = gh api -X PUT orgs/$Organizacion/teams/$Team/repos/$Organizacion/$Repositorio -f permission='push'
            $salida = $LASTEXITCODE
            if ($debug) {
                Write-Host $response   
            }
            if ($salida -ne 0) {
                Write-Host "No se pudo configurar al equipo $Team"
                $ReporteError = "$ReporteError &No se pudo configurar al equipo $Team"
            }
        }            


        # Agregar equipo con permisos de lectura, si es más de uno están separados por un &
        Write-Host " > Agregando equipos con permisos de lectura (pull)"
        
        $ReadList -Split "&" |
        ForEach-Object {
            $Team = $_
            Write-Host "   -$Team" 
            $response = gh api -X PUT orgs/$Organizacion/teams/$Team/repos/$Organizacion/$Repositorio -f permission='pull'
            $salida = $LASTEXITCODE
            if ($debug) {
                Write-Host $response   
            }
            if ($salida -ne 0) {
                Write-Host "No se pudo configurar al equipo $Team"
                $ReporteError = "$ReporteError &No se pudo configurar al equipo $Team"
            }
        }  

        # Crear ambiente develop 
        Write-Host " > Creando ambiente develop"
        $response = gh api -X PUT /repos/$Organizacion/$Repositorio/environments/develop
        $salida = $LASTEXITCODE
        if ($debug) {
            Write-Host $response   
        }                
        if ($salida -ne 0) {
            Write-Host "No se pudo crear el ambiente de develop."
            $ReporteError = "$ReporteError &No se pudo crear el ambiente de develop."
        }

        # Crear ambiente preprod
        # Y configurar equipos aprobadores, si es más de uno están separados por un &
        Write-Host " > Creando ambiente preprod, con aprobadores:"
        $AprobadoresJSONList = @()
        $AprobadorPreList -Split "&" |
            ForEach-Object {
                $Team = $_
                # Obtiene el ID del equipo
                Write-Host "   -$Team"
                $TeamID = gh api -X GET /orgs/$Organizacion/teams/$Team --jq .id
                $salida = $LASTEXITCODE
                Write-Host "      * ID: $TeamID"
                # Forma objeto de equipo y se agrega a la lista de equipos aprobadores
                $AprobadoresJSONList += @{
                    type = "Team"
                    id = [int]$TeamID
                    }
                if ($salida -ne 0) {
                    Write-Host "No se pudo obtener el ID del equipo $Team"
                    $ReporteError = "$ReporteError &No se pudo obtener el ID del equipo $Team"
                }  
            }
        
        if ($debug) {
            ConvertTo-Json $AprobadoresJSONList
            [PSCustomObject]@{
                wait_timer = 0
                reviewers = $AprobadoresJSONList
                } | ConvertTo-Json
        }
            

        [PSCustomObject]@{
                wait_timer = 0
                reviewers = $AprobadoresJSONList
        } | ConvertTo-Json | 
            gh api -X PUT /repos/$Organizacion/$Repositorio/environments/preprod --input -   
        $salida = $LASTEXITCODE
        if ($salida -ne 0) {
            Write-Host "No se pudo configurar el ambiente preprod (incluyendo los aprobadores)."
            $ReporteError = "$ReporteError &No se pudo configurar el ambiente preprod (incluyendo los aprobadores)."
        }

        # Crear ambiente production
        # Y configurar equipos aprobadores, si es más de uno están separados por un &
        Write-Host " > Creando ambiente production, con aprobadores:"
        
        $AprobadoresJSONList = @()
        $AprobadorProdList -Split "&" |
            ForEach-Object {
                $Team = $_
                Write-Host "   -$Team"
                # Obtiene el ID del equipo
                $TeamID = gh api -X GET /orgs/$Organizacion/teams/$Team --jq .id
                $salida = $LASTEXITCODE
                # Forma objeto de equipo y se agrega a la lista de equipos aprobadores
                $AprobadoresJSONList += @{
                    type = "Team"
                    id = [int]$TeamID
                    }
                if ($salida -ne 0) {
                    Write-Host "No se pudo obtener el ID del equipo $Team"
                    $ReporteError = "$ReporteError &No se pudo obtener el ID del equipo $Team"
                }
            }             


        if ($debug) {
            ConvertTo-Json $AprobadoresJSONList
            [PSCustomObject]@{
                wait_timer = 0
                reviewers = $AprobadoresJSONList
                } | ConvertTo-Json
        }

        [PSCustomObject]@{
            wait_timer = 0
            reviewers = $AprobadoresJSONList
        } | ConvertTo-Json | 
            gh api -X PUT /repos/$Organizacion/$Repositorio/environments/production --input - 
        $salida = $LASTEXITCODE
        if ($salida -ne 0) {
                Write-Host "No se pudo configurar el ambiente production (incluyendo los aprobadores)."
                $ReporteError = "$ReporteError &No se pudo configurar el ambiente production (incluyendo los aprobadores)."
        }

        # Habilitar Github Actions. Solo se puede habilitar la configuración selected para tomar las acciones seleccionadas por el administrador de la organización.        
        Write-Host " > Habilitando Github Actions"
        
        $response = gh api -X PUT /repos/$Organizacion/$Repositorio/actions/permissions -F enabled='true' -f allowed_actions='selected'
        $salida = $LASTEXITCODE
        if ($salida -ne 0) {
            Write-Host "Ocurrio un error"
            $ReporteError = "$ReporteError &No se pudo habilitar Github Actions." 
        }
        if ($debug) {
            Write-Host $response   
        }                  
    
        [PSCustomObject]@{
            repositorio = $Repositorio
            url = $ReporteUrl
            error = $ReporteError
            }  | 
        Export-Csv -NoTypeInformation -Append -Path ".\reporte_$Timestamp.csv" 
    }
