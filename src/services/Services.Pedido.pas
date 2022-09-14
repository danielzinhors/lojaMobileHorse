unit Services.Pedido;

interface

uses
  System.SysUtils, System.Classes, Services.Base, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, Providers.Request;

type
  TServicePedido = class(TServiceBase)
    mtPedidos: TFDMemTable;
    mtPedidosid: TLargeintField;
    mtPedidosid_cliente: TLargeintField;
    mtPedidosdata: TSQLTimeStampField;
    mtPedidosid_usuario: TLargeintField;
    mtPedidosnome_cliente: TWideStringField;
    mtCadastro: TFDMemTable;
    mtItens: TFDMemTable;
    mtCadastroid: TLargeintField;
    mtCadastroid_cliente: TLargeintField;
    mtCadastrodata: TSQLTimeStampField;
    mtCadastroid_usuario: TLargeintField;
    mtCadastronome_cliente: TWideStringField;
    mtItensid: TLargeintField;
    mtItensid_pedido: TLargeintField;
    mtItensid_produto: TLargeintField;
    mtItensvalor: TFMTBCDField;
    mtItensquantidade: TFMTBCDField;
    mtItensnome_produto: TWideStringField;
    mtCadastrototal: TCurrencyField;
    mtItenstotal: TCurrencyField;
    mtPedidostotal: TCurrencyField;
    procedure DataModuleCreate(Sender: TObject);
  private
    procedure AtualizarTotal();
  public
    procedure ListarPedidosUsuario;
    procedure InicializatVenda(const AIDCliente: String);
    procedure AdicionarProduto(const ADataSet: TDataSet);
  end;


implementation

uses DataSet.Serialize, System.JSON;

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

procedure TServicePedido.AdicionarProduto(const ADataSet: TDataSet);
var
  LResponse: IResponse;
begin
  if mtItens.locate('id_produto', ADataset.FieldByName('id').asString, []) then
    mtItens.edit
  else
    mtItens.append;
  mtItensid_pedido.AsLargeInt := mtCadastroid.AsLargeInt;
  mtItensid_produto.AsLargeInt := ADataSet.fieldbyName('id').AsLargeInt;
  mtItensvalor.AsCurrency := ADataSet.FieldByName('valor').AsCurrency;
  mtItensquantidade.AsInteger := mtItensquantidade.AsInteger + 1;
  mtItensnome_produto.AsString := ADataSet.FieldByName('nome').AsString;
  mtItenstotal.AsCurrency := mtItensvalor.AsCurrency * mtItensquantidade.AsInteger;
  mtItens.post;
  var LRequest := TRequest
                  .new
                  .BaseURL('http://localhost:9000')
                  .Resource('pedidos/' + mtCadastroid.asString + '/itens')
                  .AddBody(mtItens.tojsonobject);
  if mtItensid.AsLargeInt > 0 then
  begin
    LResponse := LRequest.ResourceSuffix(mtItensid.asString).put;
    if LResponse.StatusCode <> 204 then
      raise Exception.create(LResponse.Content);
  end
  else
  begin
    LResponse := LRequest.post;
    if LResponse.StatusCode <> 201 then
      raise Exception.create(LResponse.Content);
    mtItens.MergeFromJSONObject(TJSonObject(LResponse.JsonValue), false);
  end;
  AtualizarTotal;
end;

procedure TServicePedido.AtualizarTotal;
begin
  var Lid := mtItensId.AsLargeInt;
  try
    mtCadastro.Edit;
    mtCadastrototal.asCurrency := 0.00;
    mtItens.First;
    while not mtItens.eof do
    begin
      mtCadastrototal.asCurrency := mtCadastrototal.asCurrency + mtItenstotal.asCurrency;
      mtItens.next;
    end;
    mtCadastro.post;
  finally
    mtItens.locate('id', Lid, []);
  end;
end;

procedure TServicePedido.DataModuleCreate(Sender: TObject);
begin
  inherited;
  mtPedidos.open;
end;

procedure TServicePedido.InicializatVenda(const AIDCliente: String);
var
  LResponse: IResponse;
begin
  if not mtCadastro.active then
  begin
    mtCadastro.Open;
    mtCadastro.append;
    mtCadastrodata.AsDateTime := now;
    mtCadastroid_usuario.AsLargeInt := Session.User.Id;
    mtItens.Open;
  end
  else
    mtCadastro.Edit;
  mtCadastroid_cliente.AsString := AIDCliente;
  mtCadastro.Post;
  var LRequest := TRequest
                   .New
                   .BaseURL('http://localhost:9000')
                   .Resource('pedidos')
                   .AddBody(mtCadastro.TOJSonObject);
  if (mtCadastroid.AsLargeInt > 0 ) then
  begin
    LResponse := LRequest.ResourceSuffix(mtCadastroid.AsString).Post;
    if LResponse.StatusCode <> 204 then
      raise Exception.Create(LResponse.Content);
  end
  else
  begin
    LResponse := LRequest.Post;
    if LResponse.StatusCode <> 201 then
      raise Exception.Create(LResponse.Content);
    mtCadastro.MergeFromJSONObject(TJSONObject(LResponse.JSONValue), false);
  end;
end;

procedure TServicePedido.ListarPedidosUsuario;
begin
  var LResponse := TRequest
                   .New
                   .BaseURL('http://localhost:9000')
                   .Resource('pedidos')
                   .AddParam('idUsuario', Session.User.Id.ToString)
                   .Get;
  if LResponse.StatusCode <> 200 then
    raise Exception.Create(LResponse.Content);
  mtPedidos.EmptyDataSet;
  mtPedidos.LoadFromJSON(LResponse.JSONValue.GetValue<TJSONArray>('data'), false);
end;

end.
