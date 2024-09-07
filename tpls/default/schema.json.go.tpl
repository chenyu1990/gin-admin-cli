package schema

{{$name := .Name}}
func (a *{{$name}}) MarshalJSON() ([]byte, error) {
    var (
    {{- range .Fields}}
        {{- if eq .Type "time.Time"}}
            {{lowerCamel .Name}}  *time.Time
        {{- end}}
    {{- end}}
    )
    {{- range .Fields}}
    {{- if eq .Type "time.Time"}}
    if a.{{.Name}}.IsZero() == false {
        {{lowerCamel .Name}} = &a.{{.Name}}
    }
    {{- end}}
	{{- end}}
	type Alias {{$name}}
	return json.Marshal(&struct {
        {{- range .Fields}}{{$fieldName := .Name}}
            {{- if eq .Type "time.Time"}}
                {{$fieldName}} *{{.Type}} `json:"{{.JSONTag}},omitempty"` {{with .Comment}}// {{.}}{{end}}
            {{- end}}
        {{- end}}
		*Alias
	}{
        {{- range .Fields}}
            {{- if eq .Type "time.Time"}}
                {{.Name}}: {{lowerCamel .Name}},
            {{- end}}
        {{- end}}
		Alias: (*Alias)(a),
	})
}