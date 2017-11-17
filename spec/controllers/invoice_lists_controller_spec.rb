require 'spec_helper'

describe InvoiceListsController do

  let(:group) { groups(:bottom_layer_one) }
  let(:person) { people(:bottom_member) }


  context 'authorization' do
    before { sign_in(person) }

    it "may index when person has finance permission on layer group" do
      get :new, group_id: group.id
      expect(response).to be_success
    end

    it "may update when person has finance permission on layer group" do
      put :update, group_id: group.id
      expect(response).to redirect_to group_invoices_path(group)
    end

    it "may not index when person has finance permission on layer group" do
      expect do
        get :new, group_id: groups(:top_layer).id
      end.to raise_error(CanCan::AccessDenied)
    end

    it "may not edit when person has finance permission on layer group" do
      expect do
        put :update, group_id: groups(:top_layer).id
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  context 'authorized' do
    before { sign_in(person) }

    it 'GET#new renders crud/new template' do
      get :new, group_id: group.id
      expect(response).to render_template('crud/new')
    end

    it 'GET#new via xhr assigns invoice items and total' do
      xhr :get, :new, { group_id: group.id, invoice: invoice_attrs }
      expect(assigns(:invoice).invoice_items).to have(2).items
      expect(assigns(:invoice).calculated[:total]).to eq 3
      expect(response).to render_template('invoice_lists/new')
    end

    it 'POST#create creates an invoice for single member' do
      expect do
        post :create, { group_id: group.id, invoice: invoice_attrs }
      end.to change { group.invoices.count }.by(1)

      expect(response).to redirect_to group_invoices_path(group)
      expect(flash[:notice]).to eq 'Rechnung <i>Title</i> wurde erstellt.'
    end

    it 'POST#create creates an invoice for each member of group' do
      Fabricate(Group::BottomLayer::Leader.name.to_sym, group: group, person: Fabricate(:person))

      expect do
        post :create, { group_id: group.id, invoice: invoice_attrs }
      end.to change { group.invoices.count }.by(2)

      expect(response).to redirect_to group_invoices_path(group)
      expect(flash[:notice]).to eq 'Rechnung <i>Title</i> wurde für 2 Empfänger erstellt.'
    end

    it 'PUT#update informs if not invoice has been selected' do
      post :update, { group_id: group.id }
      expect(response).to redirect_to group_invoices_path(group)
      expect(flash[:alert]).to eq 'Zuerst muss eine Rechnung ausgewählt werden.'
    end

    it 'PUT#update moves invoice to sent state' do
      invoice = Invoice.create!(group: group, title: 'test', recipient: person)
      expect do
        post :update, { group_id: group.id, ids: [invoice.id] }
      end.to change { invoice.reload.updated_at }
      expect(response).to redirect_to group_invoices_path(group)
      expect(flash[:notice]).to eq 'Rechnung wurde verschickt.'
      expect(invoice.reload.state).to eq 'sent'
      expect(invoice.due_at).to be_present
      expect(invoice.sent_at).to be_present
    end

    it 'PUT#update can move multiple invoices at once' do
      invoice = Invoice.create!(group: group, title: 'test', recipient: person)
      other = Invoice.create!(group: group, title: 'test', recipient: person)
      expect do
        post :update, { group_id: group.id, ids: [invoice.id, other.id] }
      end.to change { other.reload.updated_at }
      expect(response).to redirect_to group_invoices_path(group)
      expect(flash[:notice]).to eq '2 Rechnungen wurden verschickt.'
    end

    it 'DELETE#destroy informs if no invoice has been selected' do
      delete :destroy, { group_id: group.id }
      expect(response).to redirect_to group_invoices_path(group)
      expect(flash[:alert]).to eq 'Zuerst muss eine Rechnung ausgewählt werden.'
    end

    it 'DELETE#destroy moves invoice to cancelled state' do
      invoice = Invoice.create!(group: group, title: 'test', recipient: person)
      expect do
        delete :destroy, { group_id: group.id, ids: [invoice.id] }
      end.to change { invoice.reload.updated_at }
      expect(response).to redirect_to group_invoices_path(group)
      expect(flash[:notice]).to eq 'Rechnung wurde storniert.'
      expect(invoice.reload.state).to eq 'cancelled'
    end

    it 'DELETE#destroy may move multiple invoices to cancelled state' do
      invoice = Invoice.create!(group: group, title: 'test', recipient: person)
      other = Invoice.create!(group: group, title: 'test', recipient: person)
      expect do
        delete :destroy, { group_id: group.id, ids: [invoice.id, other.id] }
      end.to change { other.reload.updated_at }
      expect(response).to redirect_to group_invoices_path(group)
      expect(flash[:notice]).to eq '2 Rechnungen wurden storniert.'
      expect(other.reload.state).to eq 'cancelled'
    end
  end

  def invoice_attrs
    {
      title: 'Title',
      invoice_items_attributes: { '1' => { name: 'item1', unit_cost: 1, count: 1},
                                  '2' => { name: 'item2', unit_cost: 2, count: 1 } }
    }
  end
end