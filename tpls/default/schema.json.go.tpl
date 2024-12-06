package schema

{{$name := .Name}}
func (a *{{$name}}) MarshalJSON() ([]byte, error) {
    var (
    {{- range .Fields}}
	    {{- if eq .OnlyCond false}}
        {{- if eq .Type "time.Time"}}
            {{lowerCamel .Name}}  *time.Time
        {{- end}}
        {{- end}}
    {{- end}}
    )
    {{- range .Fields}}
	{{- if eq .OnlyCond false}}
    {{- if eq .Type "time.Time"}}
    if a.{{.Name}}.IsZero() == false {
        {{lowerCamel .Name}} = &a.{{.Name}}
    }
    {{- end}}
    {{- end}}
	{{- end}}
	type Alias {{$name}}
	return json.Marshal(&struct {
        {{- range .Fields}}{{$fieldName := .Name}}
	        {{- if eq .OnlyCond false}}
            {{- if eq .Type "time.Time"}}
                {{$fieldName}} *{{.Type}} `json:"{{.JSONTag}},omitempty"` {{with .Comment}}// {{.}}{{end}}
            {{- end}}
            {{- end}}
        {{- end}}
		*Alias
	}{
        {{- range .Fields}}
	        {{- if eq .OnlyCond false}}
            {{- if eq .Type "time.Time"}}
                {{.Name}}: {{lowerCamel .Name}},
            {{- end}}
            {{- end}}
        {{- end}}
		Alias: (*Alias)(a),
	})
}