package biz

type {{.Name}} struct {
	Trans       *dbx.Trans
	{{.Name}}DAL *dal.{{.Name}}
}