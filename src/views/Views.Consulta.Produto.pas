unit Views.Consulta.Produto;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  Providers.Frames.Base.View, FMX.Layouts, FMX.Objects, System.Generics.Collections,
  Providers.Callback, FMX.Controls.Presentation, FMX.Edit, FMX.Effects, Providers.Aguarde,
  Services.Consulta.Produto, Providers.Frames.List.Produto, Data.Db;

type
  TFrameConsultaProduto = class(TFrameBaseView)
    Layout1: TLayout;
    retHeaderCliente: TRectangle;
    LineSeparatorHeader: TLine;
    ShadowEffect1: TShadowEffect;
    edtPesquisa: TEdit;
    btnBuscar: TButton;
    imgBuscar: TPath;
    btnVoltar: TButton;
    imgVoltar: TPath;
    retContent: TRectangle;
    vsb: TVertScrollBox;
    lytBuscaVazia: TLayout;
    txtBuscaVazia: TLabel;
    imgBuscaVazia: TPath;
    procedure btnVoltarClick(Sender: TObject);
    procedure btnBuscarClick(Sender: TObject);
  private
    FService: TServiceConsultaProduto;
    FCallBack: TCallBackDataSet;
    FListaFrames: TObjectList<TFrameListProduto>;
    procedure DesignProdutos;
    procedure OnSelectProduto(const AValue: String);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property CallBack: TCallBackDataSet read FCallBack write FCallBack;
  end;

implementation

{$R *.fmx}

procedure TFrameConsultaProduto.btnBuscarClick(Sender: TObject);
begin
  inherited;
  TAguarde.Aguardar(
    procedure
    begin
      FService.listarProdutos(edtPesquisa.text);
      TThread.Synchronize(TThread.current,
        procedure
        begin
          DesignProdutos;
        end
      )
    end
  );
end;

procedure TFrameConsultaProduto.btnVoltarClick(Sender: TObject);
begin
  inherited;
  self.owner.removecomponent(self);
  self.disposeOf;
end;

constructor TFrameConsultaProduto.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FService := TServiceConsultaProduto.Create(self);
  FListaFrames := TObjectList<TFrameListProduto>.create;
end;

procedure TFrameConsultaProduto.DesignProdutos;
begin
  lytBuscaVazia.Visible := FService.mtProdutos.isEmpty;
  vsb.Visible := not FService.mtProdutos.isEmpty;
  if FService.mtProdutos.isEmpty then
    exit;
  vsb.beginUpdate;
  FService.mtProdutos.first;
  try
    FListaFrames.clear;
    while not FService.mtProdutos.eof do
    begin
      var LFrame := TFrameListProduto.create(vsb);
      LFrame.align := TAlignLayout.top;
      LFrame.identify := FService.mtProdutosid.asString;
      LFrame.lblDescricao.text := FService.mtProdutosnome.AsString;
      LFrame.txtEstoque.text := FService.mtProdutosestoque.AsString;
      LFrame.txtValor.text := formatFloat('R$ ,0.00;', FService.mtProdutosvalor.AsCurrency);
      LFrame.Name := LFrame.classname + vsb.content.controlsCount.toString;
      LFrame.parent := vsb;
      LFrame.CallBack := OnSelectProduto;
      FListaFrames.add(LFrame);
      FService.mtProdutos.next;
    end;
  finally
    vsb.endUpdate;
  end;
end;

destructor TFrameConsultaProduto.Destroy;
begin
  FListaFrames.free;
  FService.free;
  inherited;
end;

procedure TFrameConsultaProduto.OnSelectProduto(const AValue: String);
begin
  FService.mtProdutos.Locate('id', AValue, []);
  if assigned(FCallBack) then
    FCallBack(FService.mtProdutos);
  self.owner.removecomponent(self);
  self.disposeOf;
end;

end.