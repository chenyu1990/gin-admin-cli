package schema

{{$name := .Name}}
func (a *{{$name}}Form) Validate() error {
	return nil
}