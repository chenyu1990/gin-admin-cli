package api

import (
	"{{.ModuleImportPath}}/biz"
	"{{.ModuleImportPath}}/schema"
	"{{.RootImportPath}}/pkg/ginx"
	"github.com/gin-gonic/gin"
)

{{$name := .Name}}

{{with .Comment}}// {{.}}{{else}}// Defining the `{{$name}}` api.{{end}}
type {{$name}} struct {
	{{$name}}BIZ *biz.{{$name}}
}

// @Tags {{$name}}API
// @Security ApiKeyAuth
// @Summary Query {{lowerSpace .Name}} list
{{- if not .DisablePagination}}
// @Param current query int true "pagination index" default(1)
// @Param pageSize query int true "pagination size" default(10)
{{- end}}
{{- range .Fields}}{{$fieldType := .Type}}
{{- range .Query}}
{{- with .}}
{{- if .InQuery}}
// @Param {{.FormTag}} query {{convSwaggerType $fieldType}} false "{{.Comment}}"
{{- end}}
{{- end}}
{{- end}}
{{- end}}
// @Success 200 {object} ginx.ResponseResult{data=[]schema.{{$name}}}
// @Failure 401 {object} ginx.ResponseResult
// @Failure 500 {object} ginx.ResponseResult
// @Router /api/v1/{{if .FillRouterPrefix}}{{lower .Module}}/{{end}}{{lowerHyphensPlural .Name}} [get]
func (a *{{$name}}) Query(c *gin.Context) {
	ctx := c.Request.Context()
	var params schema.{{$name}}QueryParam
	if err := ginx.ParseQuery(c, &params); err != nil {
		ginx.ResError(c, err)
		return
	}

	result, err := a.{{$name}}BIZ.Query(ctx, params)
	if err != nil {
		ginx.ResError(c, err)
		return
	}
	ginx.ResPage(c, result.Data, result.PageResult)
}

// @Tags {{$name}}API
// @Security ApiKeyAuth
// @Summary Get {{lowerSpace .Name}} record by ID
// @Param id path string true "unique id"
// @Success 200 {object} ginx.ResponseResult{data=schema.{{$name}}}
// @Failure 401 {object} ginx.ResponseResult
// @Failure 500 {object} ginx.ResponseResult
// @Router /api/v1/{{if .FillRouterPrefix}}{{lower .Module}}/{{end}}{{lowerHyphensPlural .Name}}/{id} [get]
func (a *{{$name}}) Get(c *gin.Context) {
	ctx := c.Request.Context()
	item, err := a.{{$name}}BIZ.Get(ctx, c.Param("id"))
	if err != nil {
		ginx.ResError(c, err)
		return
	}
	ginx.ResSuccess(c, item)
}

// @Tags {{$name}}API
// @Security ApiKeyAuth
// @Summary Create {{lowerSpace .Name}} record
// @Param body body schema.{{$name}}Form true "Request body"
// @Success 200 {object} ginx.ResponseResult{data=schema.{{$name}}}
// @Failure 400 {object} ginx.ResponseResult
// @Failure 401 {object} ginx.ResponseResult
// @Failure 500 {object} ginx.ResponseResult
// @Router /api/v1/{{if .FillRouterPrefix}}{{lower .Module}}/{{end}}{{lowerHyphensPlural .Name}} [post]
func (a *{{$name}}) Create(c *gin.Context) {
	ctx := c.Request.Context()
	item := new(schema.{{$name}}Form)
	if err := ginx.ParseJSON(c, item); err != nil {
		ginx.ResError(c, err)
		return
	} else if err := item.Validate(); err != nil {
		ginx.ResError(c, err)
		return
	}

	result, err := a.{{$name}}BIZ.Create(ctx, item)
	if err != nil {
		ginx.ResError(c, err)
		return
	}
	ginx.ResSuccess(c, result)
}

// @Tags {{$name}}API
// @Security ApiKeyAuth
// @Summary Update {{lowerSpace .Name}} record by ID
// @Param id path string true "unique id"
// @Param body body schema.{{$name}}Form true "Request body"
// @Success 200 {object} ginx.ResponseResult
// @Failure 400 {object} ginx.ResponseResult
// @Failure 401 {object} ginx.ResponseResult
// @Failure 500 {object} ginx.ResponseResult
// @Router /api/v1/{{if .FillRouterPrefix}}{{lower .Module}}/{{end}}{{lowerHyphensPlural .Name}}/{id} [put]
func (a *{{$name}}) Update(c *gin.Context) {
	ctx := c.Request.Context()
	item := new(schema.{{$name}}Form)
	if err := ginx.ParseJSON(c, item); err != nil {
		ginx.ResError(c, err)
		return
	} else if err := item.Validate(); err != nil {
		ginx.ResError(c, err)
		return
	}

	err := a.{{$name}}BIZ.Update(ctx, c.Param("id"), item)
	if err != nil {
		ginx.ResError(c, err)
		return
	}
	ginx.ResOK(c)
}

// @Tags {{$name}}API
// @Security ApiKeyAuth
// @Summary Delete {{lowerSpace .Name}} record by ID
// @Param id path string true "unique id"
// @Success 200 {object} ginx.ResponseResult
// @Failure 401 {object} ginx.ResponseResult
// @Failure 500 {object} ginx.ResponseResult
// @Router /api/v1/{{if .FillRouterPrefix}}{{lower .Module}}/{{end}}{{lowerHyphensPlural .Name}}/{id} [delete]
func (a *{{$name}}) Delete(c *gin.Context) {
	ctx := c.Request.Context()
	err := a.{{$name}}BIZ.Delete(ctx, c.Param("id"))
	if err != nil {
		ginx.ResError(c, err)
		return
	}
	ginx.ResOK(c)
}
