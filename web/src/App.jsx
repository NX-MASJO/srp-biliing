import React, { useEffect, useMemo, useState } from 'react';
import {
  Archive, Bell, Building2, Check, ChevronDown, CircleDollarSign, FilePlus2, Plus,
  FileText, Palette, Receipt, Search, Settings, Trash2, Users, X
} from 'lucide-react';

const translations = {
  en: {
    title: 'Billing desk', subtitle: 'Invoices, company accounts and commissions',
    invoices: 'Invoices', create: 'New invoice', templates: 'Job templates',
    createTemplate: 'Create template', templateEditor: 'Template details',
    commissions: 'Commissions', settings: 'Appearance', search: 'Search invoices...',
    manageSociety: 'Manage society',
    all: 'All statuses', pending: 'Pending', paid: 'Paid', cancelled: 'Cancelled',
    empty: 'No invoices found.', amount: 'Amount', titleField: 'Invoice title',
    type: 'Invoice type', personal: 'Player invoice', job: 'Job invoice',
    b2b: 'Company invoice', target: 'Nearby player server ID', recipient: 'Bill company',
    subtotal: 'Amount before discount', discount: 'Discount %', due: 'Due date',
    attachments: 'Items', addItem: 'Add item', item: 'Item', itemName: 'Item name',
    quantity: 'Quantity', unitPrice: 'Unit price', lineTotal: 'Line total',
    manualAmount: 'Manual amount', chooseTemplate: 'Select approved template',
    templateRequired: 'An authorized manager must create an approved template before this job can bill.',
    templateSelectionRequired: 'Select an approved template to continue.',
    maxItemsReached: 'Maximum number of items reached.',
    createButton: 'Create invoice',
    bank: 'Bank transfer', cash: 'Cash', pay: 'Pay invoice', cancel: 'Cancel',
    from: 'From', to: 'To', receipt: 'Receipt', number: 'Invoice #',
    templateName: 'Template name', saveTemplate: 'Save as template',
    applyTemplate: 'Apply template', delete: 'Delete', employee: 'Employee',
    commission: 'Commission', commissionHistory: 'Commission history',
    payCommission: 'Pay commission', noCommissions: 'No commission records.',
    theme: 'Live theme editor', saveTheme: 'Save theme', accent: 'Accent',
    background: 'Background', surface: 'Surface', text: 'Text',
    adminOnly: 'Admin settings are only available to server administrators.',
    close: 'Close', refresh: 'Refresh', templateEmpty: 'No job templates saved.',
    paymentSuccess: 'Invoice paid successfully.', createSuccess: 'Invoice created.',
    actionFailed: 'The action could not be completed.', templateSuccess: 'Template saved.',
    commissionSuccess: 'Commission paid.', b2bHint: 'Only company managers can issue or pay company invoices.',
    total: 'Total', discountLabel: 'Discount', dueLabel: 'Due', save: 'Save',
    archive: 'Invoice history', targetRequired: 'Select a nearby player from ox_target first.',
    removeConfirm: 'Delete this template?', orderReceipt: 'ORDER RECEIPT',
    description: 'Description', issued: 'Issued'
    ,paidInvoices: 'Invoices paid', unpaidInvoices: 'Invoices unpaid',
    refreshNearby: 'Refresh nearby', sendInvoice: 'Send invoice',
    receiptPreview: 'Receipt preview', tax: 'Tax',
    invoiceStatus: 'Invoice status', count: 'Count'
  },
  id: {
    title: 'Menu Billing', subtitle: 'Tagihan, rekening perusahaan, dan komisi',
    invoices: 'Tagihan', create: 'Buat tagihan', templates: 'Template job',
    createTemplate: 'Buat template', templateEditor: 'Detail template',
    commissions: 'Komisi', settings: 'Tampilan', search: 'Cari tagihan...',
    manageSociety: 'Kelola society',
    all: 'Semua status', pending: 'Menunggu', paid: 'Lunas', cancelled: 'Dibatalkan',
    empty: 'Tagihan tidak ditemukan.', amount: 'Jumlah', titleField: 'Judul tagihan',
    type: 'Jenis tagihan', personal: 'Tagihan pemain', job: 'Tagihan job',
    b2b: 'Tagihan perusahaan', target: 'ID server pemain terdekat', recipient: 'Perusahaan tujuan',
    subtotal: 'Jumlah sebelum diskon', discount: 'Diskon %', due: 'Jatuh tempo',
    attachments: 'Item', addItem: 'Tambah item', item: 'Item', itemName: 'Nama item',
    quantity: 'Kuantitas', unitPrice: 'Harga satuan', lineTotal: 'Total baris',
    manualAmount: 'Jumlah manual', chooseTemplate: 'Pilih template yang disetujui',
    templateRequired: 'Pengelola yang berwenang harus membuat template sebelum job ini dapat menagih.',
    templateSelectionRequired: 'Pilih template yang disetujui untuk melanjutkan.',
    maxItemsReached: 'Jumlah item maksimum tercapai.',
    createButton: 'Buat tagihan',
    bank: 'Transfer bank', cash: 'Tunai', pay: 'Bayar tagihan', cancel: 'Batalkan',
    from: 'Dari', to: 'Kepada', receipt: 'Struk', number: 'Tagihan #',
    templateName: 'Nama template', saveTemplate: 'Simpan template',
    applyTemplate: 'Gunakan template', delete: 'Hapus', employee: 'Karyawan',
    commission: 'Komisi', commissionHistory: 'Riwayat komisi',
    payCommission: 'Bayar komisi', noCommissions: 'Belum ada catatan komisi.',
    theme: 'Editor tema langsung', saveTheme: 'Simpan tema', accent: 'Aksen',
    background: 'Latar belakang', surface: 'Permukaan', text: 'Teks',
    adminOnly: 'Pengaturan hanya tersedia untuk administrator server.',
    close: 'Tutup', refresh: 'Muat ulang', templateEmpty: 'Belum ada template job.',
    paymentSuccess: 'Tagihan berhasil dibayar.', createSuccess: 'Tagihan berhasil dibuat.',
    actionFailed: 'Tindakan tidak dapat diselesaikan.', templateSuccess: 'Template berhasil disimpan.',
    commissionSuccess: 'Komisi berhasil dibayarkan.', b2bHint: 'Hanya pengelola perusahaan yang dapat membuat atau membayar tagihan perusahaan.',
    total: 'Total', discountLabel: 'Diskon', dueLabel: 'Jatuh tempo', save: 'Simpan',
    archive: 'Riwayat tagihan', targetRequired: 'Pilih pemain terdekat melalui ox_target terlebih dahulu.',
    removeConfirm: 'Hapus template ini?', orderReceipt: 'STRUK PEMBAYARAN',
    description: 'Deskripsi', issued: 'Diterbitkan',
    paidInvoices: 'Tagihan lunas', unpaidInvoices: 'Tagihan belum lunas',
    refreshNearby: 'Pilih pemain terdekat', sendInvoice: 'Kirim tagihan',
    receiptPreview: 'Pratinjau struk', tax: 'Pajak',
    invoiceStatus: 'Status tagihan', count: 'Jumlah'
  }
};

const emptyTheme = { accent: '#72f33d', background: '#080d09', surface: '#111a12', text: '#f0f7ed' };

async function nui(endpoint, payload = {}) {
  const response = await fetch(`https://${GetParentResourceName()}/${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(payload)
  });
  return response.json();
}

function Barcode({ value }) {
  const seed = String(value || '0').split('').reduce((sum, char) => sum + char.charCodeAt(0), 0);
  return (
    <div className="barcode-wrap" aria-label={`Barcode ${value}`}>
      <div className="barcode" style={{ '--seed': seed % 9 }} />
      <span>{value}</span>
    </div>
  );
}

function getAttachmentSubtotal(attachments) {
  return (attachments || []).reduce((total, line) => {
    const unitPrice = Math.min(1000000, Math.max(0, Math.trunc(Number(line.unitPrice) || 0)));
    const quantity = Math.min(50, Math.max(0, Math.trunc(Number(line.quantity) || 0)));
    return total + unitPrice * quantity;
  }, 0);
}

function getReceiptLines(attachments) {
  return (attachments || []).map((line) => ({ ...line, quantity: Number(line.quantity) || 0 }));
}

function TemplateItemEditor({ items, onChange, t, maxItems }) {
  function updateLine(index, updates) {
    onChange(items.map((line, lineIndex) => (
      lineIndex === index ? { ...line, ...updates } : line
    )));
  }

  function addLine() {
    if (items.length >= maxItems) return;
    onChange([...items, { id: `item-${Date.now()}-${items.length}`, label: '', quantity: 1, unitPrice: '' }]);
  }

  return (
    <div className="item-editor full">
      {items.length > 0 && <div className="item-editor-head">
        <span>{t.itemName}</span><span>{t.quantity}</span><span>{t.unitPrice}</span><span>{t.lineTotal}</span><span />
      </div>}
      {items.map((line, index) => {
        const quantity = Math.min(50, Math.max(0, Number(line.quantity) || 0));
        const unitPrice = Number(line.unitPrice) || 0;
        return (
          <div className="item-editor-row" key={`${index}-${line.id}`}>
            <input aria-label={t.itemName} maxLength="64" required value={line.label} onChange={(event) => updateLine(index, { label: event.target.value })} />
            <input aria-label={t.quantity} type="number" min="1" max="50" required value={line.quantity} onChange={(event) => updateLine(index, { quantity: event.target.value })} />
            <input aria-label={t.unitPrice} type="number" min="1" max="1000000" required value={line.unitPrice} onChange={(event) => updateLine(index, { unitPrice: event.target.value })} />
            <strong className="item-total">${unitPrice * quantity}</strong>
            <button type="button" className="icon-button danger item-remove" aria-label={t.delete} title={t.delete} onClick={() => onChange(items.filter((_, lineIndex) => lineIndex !== index))}><Trash2 size={14} /></button>
          </div>
        );
      })}
      <button type="button" className="button button-soft item-add" disabled={items.length >= maxItems} onClick={addLine}><Plus size={14} />{t.addItem}</button>
      {items.length >= maxItems && <small>{t.maxItemsReached}</small>}
    </div>
  );
}

function InvoiceTemplateItems({ items, onChange, t }) {
  function updateQuantity(index, quantity) {
    onChange(items.map((line, lineIndex) => (
      lineIndex === index ? { ...line, quantity } : line
    )));
  }

  if (!items.length) return null;
  return (
    <div className="item-editor full">
      <div className="item-editor-head invoice-item-head">
        <span>{t.itemName}</span><span>{t.quantity}</span><span>{t.unitPrice}</span><span>{t.lineTotal}</span>
      </div>
      {items.map((line, index) => (
        <div className="invoice-item-row" key={`${index}-${line.id}`}>
          <span>{line.label}</span>
          <input aria-label={t.quantity} type="number" min="1" max="50" required value={line.quantity} onChange={(event) => updateQuantity(index, event.target.value)} />
          <span className="item-price">${line.unitPrice}</span>
          <strong className="item-total">${(Number(line.unitPrice) || 0) * Math.min(50, Math.max(0, Number(line.quantity) || 0))}</strong>
        </div>
      ))}
    </div>
  );
}

function ReceiptCard({ invoice, t, brand, onPay, onCancel, compact = false }) {
  const lines = invoice.attachments?.length
    ? invoice.attachments
    : [{ id: `invoice-${invoice.id}`, label: invoice.title, quantity: 1, unitPrice: invoice.subtotal }];

  return (
    <article className={`receipt-card ${compact ? 'compact' : ''}`}>
      <div className="receipt-paper">
        <header className="paper-brand">
          <strong>{brand || invoice.sender_society || invoice.sender_name || 'BILLING'}</strong>
          <span>{t.to}: {invoice.recipient_name || invoice.recipient_society || '—'}</span>
        </header>
        <div className="paper-divider" />
        <div className="paper-kicker">{t.orderReceipt}</div>
        <div className="paper-table-heading"><strong>{t.description}</strong><strong>{t.amount}</strong></div>
        <div className="paper-lines">
          {lines.map((line, index) => (
            <div className="paper-line" key={`${line.id}-${index}`}>
              <span>{line.quantity}x {line.label}</span>
              <strong>${line.unitPrice * line.quantity}</strong>
              {line.description && <small>{line.description}</small>}
            </div>
          ))}
        </div>
        <div className="paper-totals">
          {invoice.discount_percent > 0 && <div><span>{t.discountLabel}</span><span>−${invoice.subtotal - invoice.total}</span></div>}
          <div><span>{t.amount}</span><span>${invoice.subtotal}</span></div>
          <div className="paper-grand-total"><strong>{t.total}</strong><strong>${invoice.total}</strong></div>
        </div>
        <div className="paper-barcode">
          <Barcode value={`SRP-${invoice.id}`} />
          <small>{t.issued}: {invoice.created_at || '—'} · {t.dueLabel}: {invoice.due_date || '—'}</small>
        </div>
      </div>
      <div className="receipt-controls">
        <span className={`status status-${invoice.status}`}>{invoice.status}</span>
        <div className="actions">
          {invoice.canPay && (invoice.invoice_type === 'b2b'
            ? <button className="button" onClick={() => onPay(invoice.id, 'bank')}>{t.bank}</button>
            : <><button className="button button-soft" onClick={() => onPay(invoice.id, 'cash')}>{t.cash}</button><button className="button" onClick={() => onPay(invoice.id, 'bank')}>{t.bank}</button></>)}
          {invoice.canCancel && <button className="icon-button danger" title={t.cancel} onClick={() => onCancel(invoice.id)}><X size={16} /></button>}
        </div>
      </div>
    </article>
  );
}

export default function App() {
  const [visible, setVisible] = useState(false);
  const [dashboard, setDashboard] = useState(null);
  const [sharedReceipt, setSharedReceipt] = useState(null);
  const [section, setSection] = useState('invoices');
  const [targetId, setTargetId] = useState('');
  const [selectedSocietyJob, setSelectedSocietyJob] = useState('');
  const [status, setStatus] = useState('');
  const [search, setSearch] = useState('');
  const [notice, setNotice] = useState('');
  const [theme, setTheme] = useState(emptyTheme);
  const [form, setForm] = useState({ invoiceType: 'personal', title: '', amount: '', discountPercent: 0, dueDate: '', attachments: [], templateId: '', targetId: '', recipientSociety: '', templateName: '' });

  const locale = dashboard?.locale === 'id' ? 'id' : 'en';
  const t = translations[locale];
  const invoices = dashboard?.archive || [];
  const filtered = useMemo(() => invoices.filter((invoice) => {
    const text = `${invoice.title} ${invoice.sender_name || ''} ${invoice.recipient_name || ''} ${invoice.id}`.toLowerCase();
    return text.includes(search.toLowerCase());
  }), [invoices, search]);

  useEffect(() => {
    const receive = (event) => {
      if (event.data?.action === 'open') {
        setSharedReceipt(null);
        const data = event.data.dashboard || {};
        setDashboard(data);
        setSelectedSocietyJob(data.selectedSocietyJob || '');
        setTheme({ ...emptyTheme, ...(data.theme || {}) });
        setTargetId(event.data.targetId ? String(event.data.targetId) : '');
        setSearch('');
        setForm((current) => ({ ...current, targetId: event.data.targetId ? String(event.data.targetId) : '' }));
        setSection(event.data.initialSection || 'invoices');
        setStatus(event.data.initialStatus || '');
        setVisible(true);
      }
      if (event.data?.action === 'showReceipt' && event.data.receipt) {
        setSharedReceipt(event.data.receipt);
        setVisible(true);
      }
      if (event.data?.action === 'close') {
        setVisible(false);
        setSharedReceipt(null);
      }
    };
    window.addEventListener('message', receive);
    const keydown = (event) => {
      if (event.key === 'Escape' && visible) close();
    };
    window.addEventListener('keydown', keydown);
    return () => {
      window.removeEventListener('message', receive);
      window.removeEventListener('keydown', keydown);
    };
  }, [visible]);

  useEffect(() => {
    document.documentElement.style.setProperty('--accent', theme.accent);
    document.documentElement.style.setProperty('--app-bg', theme.background);
    document.documentElement.style.setProperty('--surface', theme.surface);
    document.documentElement.style.setProperty('--app-text', theme.text);
  }, [theme]);

  useEffect(() => {
    if (!visible || section !== 'invoices') return undefined;
    const timer = window.setTimeout(() => refresh(status), 250);
    return () => window.clearTimeout(timer);
  }, [search, status, visible, section]);

  async function close() {
    setVisible(false);
    await nui('close');
  }

  async function refresh(nextStatus = status, societyJob = selectedSocietyJob) {
    const result = await nui('refresh', { status: nextStatus || undefined, search: search || undefined, societyJob });
    if (result.ok) {
      setDashboard(result.dashboard);
      setTheme({ ...emptyTheme, ...(result.dashboard.theme || {}) });
    }
  }

  async function act(endpoint, payload, successMessage) {
    setNotice('');
    const result = await nui(endpoint, payload);
    if (!result?.ok) {
      setNotice(result?.error || t.actionFailed);
      return false;
    }
    setNotice(successMessage);
    await refresh();
    return true;
  }

  async function submitInvoice(event) {
    event.preventDefault();
    if (form.invoiceType === 'job' && !form.templateId) {
      setNotice(t.templateRequired);
      return;
    }
    const payload = {
      ...form,
      targetId: Number(form.targetId || targetId),
      amount: invoiceSubtotal,
      discountPercent: Number(form.discountPercent),
      attachments: selectedTemplate
        ? form.attachments.map(({ id, quantity }) => ({ id, quantity }))
        : form.attachments,
      societyJob: selectedSocietyJob
    };
    if (payload.invoiceType !== 'b2b' && !payload.targetId) {
      setNotice(t.targetRequired);
      return;
    }
    const success = await act('createInvoice', payload, t.createSuccess);
    if (success) {
      setForm((current) => ({ ...current, title: '', amount: '', attachments: [], templateId: '', templateName: '' }));
      setSection('invoices');
    }
  }

  async function saveTemplate() {
    const success = await act('saveTemplate', {
      ...form,
      societyJob: selectedSocietyJob,
      amount: form.attachments.length ? getAttachmentSubtotal(form.attachments) : Number(form.amount),
      discountPercent: Number(form.discountPercent),
      attachments: form.attachments,
      name: form.templateName
    }, t.templateSuccess);
    if (success) {
      setForm((current) => ({ ...current, title: '', amount: '', discountPercent: 0, attachments: [], templateId: '', templateName: '' }));
      setSection('templates');
    }
  }

  async function submitTemplate(event) {
    event.preventDefault();
    await saveTemplate();
  }

  function applyTemplate(id, preserveInvoiceType = false) {
    const template = dashboard?.templates?.find((item) => String(item.id) === String(id));
    if (!template) return;
    setForm((current) => ({
      ...current,
      invoiceType: preserveInvoiceType && current.invoiceType === 'b2b' ? 'b2b' : 'job',
      title: template.title,
      amount: String(template.subtotal),
      discountPercent: template.discount_percent,
      templateId: String(template.id),
      attachments: (template.attachments || []).map((line) => ({ ...line, quantity: line.quantity }))
    }));
    setSection('create');
  }

  function selectInvoiceTemplate(id) {
    if (!id) {
      setForm((current) => ({ ...current, templateId: '', attachments: [], amount: '', title: '', discountPercent: 0 }));
      return;
    }
    applyTemplate(id, true);
  }

  function changeSociety(jobName) {
    setSelectedSocietyJob(jobName);
    setForm((current) => ({
      ...current,
      templateId: '',
      attachments: current.invoiceType === 'personal' ? current.attachments : [],
      title: current.invoiceType === 'personal' ? current.title : '',
      amount: current.invoiceType === 'personal' ? current.amount : '',
      discountPercent: current.invoiceType === 'personal' ? current.discountPercent : 0
    }));
    refresh(status, jobName);
  }

  async function changeStatus(value) {
    setStatus(value);
  }

  if (sharedReceipt) {
    const receiptT = translations[sharedReceipt.locale === 'id' ? 'id' : 'en'];
    return (
      <main className="receipt-share-shell">
        <section className="receipt-share-window" aria-label={receiptT.receipt}>
          <div className="receipt-share-heading">
            <div><div className="eyebrow">{receiptT.receipt}</div><h1>{receiptT.number}{sharedReceipt.id}</h1></div>
            <button type="button" className="icon-button" title={receiptT.close} onClick={close}><X size={18} /></button>
          </div>
          <ReceiptCard
            compact
            t={receiptT}
            brand={sharedReceipt.sender_society || sharedReceipt.sender_name}
            invoice={sharedReceipt}
            onPay={() => {}}
            onCancel={() => {}}
          />
        </section>
      </main>
    );
  }

  if (!visible || !dashboard) return null;

  const selectedTemplate = dashboard.templates?.find((template) => String(template.id) === form.templateId);
  const invoiceSubtotal = selectedTemplate
    ? (form.attachments.length ? getAttachmentSubtotal(form.attachments) : Number(selectedTemplate.subtotal) || 0)
    : (form.attachments.length ? getAttachmentSubtotal(form.attachments) : Number(form.amount) || 0);
  const invoiceReceiptLines = getReceiptLines(form.attachments);
  const templateSubtotal = form.attachments.length
    ? getAttachmentSubtotal(form.attachments)
    : Number(form.amount) || 0;

  const nav = [
    { id: 'invoices', label: t.invoices, icon: Receipt },
    { id: 'create', label: t.create, icon: FilePlus2 }
  ];
  if (dashboard.canManageTemplates) nav.push({ id: 'templates', label: t.templates, icon: Archive });
  if (dashboard.canManageCommissions) nav.push({ id: 'commissions', label: t.commissions, icon: CircleDollarSign });
  if (dashboard.isAdmin) nav.push({ id: 'settings', label: t.settings, icon: Palette });

  return (
    <main className="app-shell">
      <section className="window">
        <div className="device-screen">
          <header className="topbar">
            <img className="brand-logo" src="./images/srp-logo.png" alt="SRP logo" />
            <div className="brand-title"><strong>{dashboard.profileName || t.title}</strong><span>{dashboard.isAdmin ? dashboard.societyLabel : (dashboard.jobLabel || t.subtitle)}</span></div>
            <div className="topbar-actions"><button className="icon-button notification-button" title={t.refresh} onClick={() => refresh()}><Bell size={16} /></button><button className="icon-button" title={t.close} onClick={close}><X size={18} /></button></div>
          </header>
          <div className="workspace">
            <aside className="sidebar">
              <div className="nav-label">{t.archive}</div>
              {dashboard.isAdmin && <label className="admin-society-select"><span>{t.manageSociety}</span><select value={selectedSocietyJob} onChange={(event) => changeSociety(event.target.value)}>{dashboard.allSocieties?.map((society) => <option key={society.job} value={society.job}>{society.label}</option>)}</select></label>}
              {nav.map(({ id, label, icon: Icon }) => (
                <button key={id} className={`nav-item ${section === id ? 'active' : ''}`} onClick={() => setSection(id)}>
                  <Icon size={17} /><span>{label}</span>
                </button>
              ))}
              <div className="sidebar-foot"><span className="online-dot" /> QBCore · Secure billing</div>
            </aside>
            <section className="content">
            {notice && <div className="notice" role="status">{notice}</div>}
            {section === 'invoices' && <div className="section-view">
              <div className="section-heading">
                <div><div className="eyebrow">{t.archive}</div><h1>{t.invoices}</h1></div>
                <button className="button" onClick={() => setSection('create')}><FilePlus2 size={16} /> {t.create}</button>
              </div>
              <div className="invoice-overview" aria-label={t.invoiceStatus}>
                <div className="invoice-overview-heading">
                  <span className="eyebrow">{t.invoiceStatus}</span>
                  <span className="invoice-overview-caption">{t.archive}</span>
                </div>
                <div className="invoice-overview-grid">
                  <div className="invoice-overview-card paid">
                    <span className="summary-status-dot" />
                    <span className="invoice-overview-label">{t.paidInvoices}</span>
                    <strong>{dashboard.archive?.filter((invoice) => invoice.status === 'paid').length || 0}</strong>
                  </div>
                  <div className="invoice-overview-card pending">
                    <span className="summary-status-dot" />
                    <span className="invoice-overview-label">{t.unpaidInvoices}</span>
                    <strong>{dashboard.archive?.filter((invoice) => invoice.status === 'pending').length || 0}</strong>
                  </div>
                </div>
              </div>
              <div className="toolbar">
                <label className="searchbox"><Search size={16} /><input value={search} onChange={(event) => setSearch(event.target.value)} placeholder={t.search} /></label>
                <label className="select-wrap"><select value={status} onChange={(event) => changeStatus(event.target.value)}><option value="">{t.all}</option><option value="pending">{t.pending}</option><option value="paid">{t.paid}</option><option value="cancelled">{t.cancelled}</option></select><ChevronDown size={14} /></label>
              </div>
              <div className="invoice-list">
                {filtered.map((invoice) => <ReceiptCard key={invoice.id} invoice={invoice} t={t} brand={dashboard.societyLabel} compact
                  onPay={(id, account) => act('payInvoice', { id, account }, t.paymentSuccess)}
                  onCancel={(id) => act('cancelInvoice', { id }, t.cancel)} />)}
                {!filtered.length && <div className="empty-state"><FileText size={28} /><p>{t.empty}</p></div>}
              </div>
            </div>}

            {section === 'create' && <div className="section-view create-dashboard">
              <div className="create-heading">
                <div className="section-heading">
                  <div><div className="eyebrow">{t.create}</div><h1>{t.create}</h1><p className="section-description">{t.subtitle}</p></div>
                  <button type="submit" form="invoice-form" className="button"><FilePlus2 size={15} />{t.sendInvoice}</button>
                </div>
              </div>
              <div className="create-columns">
              <form id="invoice-form" className="form-grid" onSubmit={submitInvoice}>
                <div className="invoice-form-toolbar">
                  <div className="type-switch">
                    <button type="button" className={form.invoiceType === 'personal' ? 'selected' : ''} onClick={() => setForm({ ...form, invoiceType: 'personal', attachments: [], templateId: '', amount: '', title: '', discountPercent: 0 })}>{t.personal}</button>
                    {(dashboard.canCreateJobInvoice || dashboard.canCreateB2B) && <button type="button" className={form.invoiceType === 'job' ? 'selected' : ''} onClick={() => setForm({ ...form, invoiceType: 'job', attachments: [], templateId: '', amount: '', title: '', discountPercent: 0 })}>{t.job}</button>}
                    {dashboard.canCreateB2B && <button type="button" className={form.invoiceType === 'b2b' ? 'selected' : ''} onClick={() => setForm({ ...form, invoiceType: 'b2b', attachments: [], templateId: '', amount: '', title: '', discountPercent: 0 })}>{t.b2b}</button>}
                  </div>
                  <button type="button" className="button button-soft" onClick={() => setNotice(t.targetRequired)}><Users size={14} />{t.refreshNearby}</button>
                </div>
                <label className="field full"><span>{t.type}</span><select value={form.invoiceType} onChange={(event) => setForm({ ...form, invoiceType: event.target.value, attachments: [], templateId: '', amount: '', title: '', discountPercent: 0 })}>
                  <option value="personal">{t.personal}</option>
                  {dashboard.canCreateJobInvoice && <option value="job">{t.job}</option>}
                  {dashboard.canCreateB2B && <option value="b2b">{t.b2b}</option>}
                </select></label>
                {form.invoiceType === 'b2b'
                  ? <label className="field full"><span>{t.recipient}</span><select value={form.recipientSociety} onChange={(event) => setForm({ ...form, recipientSociety: event.target.value })}><option value="">—</option>{dashboard.societies?.map((society) => <option key={society.job} value={society.job}>{society.label}</option>)}</select></label>
                  : <label className="field full"><span>{t.target}</span><input type="number" min="1" value={form.targetId || targetId} onChange={(event) => setForm({ ...form, targetId: event.target.value })} placeholder={t.targetRequired} /></label>}
                <label className="field full"><span>{t.titleField}</span><input maxLength="80" required readOnly={Boolean(selectedTemplate)} value={form.title} onChange={(event) => setForm({ ...form, title: event.target.value })} /></label>
                <label className="field"><span>{t.discount}</span><input type="number" min="0" max="90" readOnly={Boolean(selectedTemplate)} value={form.discountPercent} onChange={(event) => setForm({ ...form, discountPercent: event.target.value })} /></label>
                <label className="field"><span>{t.due}</span><input type="date" value={form.dueDate} onChange={(event) => setForm({ ...form, dueDate: event.target.value })} /></label>
                {form.invoiceType === 'job' && dashboard.templates?.length > 0 && <label className="field full"><span>{t.applyTemplate}</span><select value={form.templateId} onChange={(event) => selectInvoiceTemplate(event.target.value)}><option value="">{t.chooseTemplate}</option>{dashboard.templates.map((template) => <option key={template.id} value={template.id}>{template.name}</option>)}</select></label>}
                {(form.invoiceType === 'personal' || form.invoiceType === 'b2b') && <div className="field full"><span>{t.attachments}</span><TemplateItemEditor items={form.attachments} onChange={(attachments) => setForm({ ...form, attachments, amount: getAttachmentSubtotal(attachments) })} t={t} maxItems={dashboard.maxAttachments || 8} /></div>}
                {selectedTemplate && <div className="field full"><span>{t.attachments}</span><InvoiceTemplateItems items={form.attachments} onChange={(attachments) => setForm({ ...form, attachments })} t={t} /></div>}
                {form.invoiceType === 'job' && !selectedTemplate && <p className="form-hint full">{dashboard.templates?.length ? t.templateSelectionRequired : t.templateRequired}</p>}
                <label className="field"><span>{t.subtotal}</span><input type="number" min="1" max="1000000" required readOnly={Boolean(selectedTemplate) || form.attachments.length > 0 || form.invoiceType === 'job'} value={invoiceSubtotal || form.amount} onChange={(event) => setForm({ ...form, amount: event.target.value })} /></label>
                {form.invoiceType === 'b2b' && <p className="form-hint full"><Building2 size={15} />{t.b2bHint}</p>}
                <div className="form-actions full">
                  <button type="submit" className="button"><Check size={16} />{t.createButton}</button>
                </div>
              </form>
              <aside className="receipt-preview-panel">
                <div className="preview-heading"><div className="eyebrow">{t.receiptPreview}</div><span className="preview-live-dot" /></div>
                <ReceiptCard
                  compact
                  t={t}
                  brand={dashboard.societyLabel || dashboard.jobLabel}
                  invoice={{
                    id: 'PREVIEW',
                    invoice_type: form.invoiceType,
                    sender_name: dashboard.profileName || t.title,
                    sender_society: dashboard.societyLabel,
                    recipient_name: form.invoiceType === 'b2b'
                      ? dashboard.societies?.find((society) => society.job === form.recipientSociety)?.label
                      : (form.targetId || targetId ? `Player #${form.targetId || targetId}` : t.target),
                    title: form.title || t.titleField,
                    subtotal: invoiceSubtotal,
                    discount_percent: Number(form.discountPercent) || 0,
                    total: Math.max(0, Math.round(invoiceSubtotal * (100 - (Number(form.discountPercent) || 0)) / 100)),
                    due_date: form.dueDate || '—',
                    created_at: new Date().toLocaleDateString(locale === 'id' ? 'id-ID' : 'en-US'),
                    status: 'pending',
                    attachments: invoiceReceiptLines,
                    canPay: false,
                    canCancel: false
                  }}
                  onPay={() => {}}
                  onCancel={() => {}}
                />
              </aside>
              </div>
            </div>}

            {section === 'templates' && <div className="section-view">
              <div className="section-heading"><div><div className="eyebrow">{t.templates}</div><h1>{t.templates}</h1></div><button className="button" onClick={() => setSection('template-create')}><FilePlus2 size={16} /> {t.createTemplate}</button></div>
              <div className="template-list">{dashboard.templates?.map((template) => <article className="template-card" key={template.id}>
                <div className="template-icon"><FileText size={19} /></div><div className="template-copy"><strong>{template.name}</strong><span>{template.title} · ${template.subtotal}</span></div>
                <button className="button button-soft" onClick={() => applyTemplate(template.id)}>{t.applyTemplate}</button>
                <button className="icon-button danger" title={t.delete} onClick={() => window.confirm(t.removeConfirm) && act('deleteTemplate', { id: template.id, societyJob: selectedSocietyJob }, t.delete)}><Trash2 size={16} /></button>
              </article>)}{!dashboard.templates?.length && <div className="empty-state"><Archive size={28} /><p>{t.templateEmpty}</p></div>}</div>
            </div>}

            {section === 'template-create' && dashboard.canManageTemplates && <div className="section-view create-dashboard">
              <div className="section-heading">
                <div><div className="eyebrow">{t.templates}</div><h1>{t.createTemplate}</h1></div>
                <button type="button" className="button button-soft" onClick={() => setSection('templates')}><Archive size={15} />{t.templates}</button>
              </div>
              <div className="create-columns">
                <form id="template-form" className="form-grid" onSubmit={submitTemplate}>
                  <label className="field full"><span>{t.templateName}</span><input maxLength="48" required value={form.templateName} onChange={(event) => setForm({ ...form, templateName: event.target.value })} /></label>
                  <label className="field full"><span>{t.titleField}</span><input maxLength="80" required value={form.title} onChange={(event) => setForm({ ...form, title: event.target.value })} /></label>
                  <label className="field"><span>{t.discount}</span><input type="number" min="0" max="90" value={form.discountPercent} onChange={(event) => setForm({ ...form, discountPercent: event.target.value })} /></label>
                  <div className="field full"><span>{t.attachments}</span><TemplateItemEditor items={form.attachments} onChange={(attachments) => setForm({ ...form, attachments })} t={t} maxItems={dashboard.maxAttachments || 8} /></div>
                  <label className="field"><span>{t.subtotal}</span><input type="number" min="1" max="1000000" required readOnly={form.attachments.length > 0} value={templateSubtotal} onChange={(event) => setForm({ ...form, amount: event.target.value })} /></label>
                  <div className="form-actions full"><button type="submit" className="button"><Check size={16} />{t.saveTemplate}</button></div>
                </form>
                <aside className="receipt-preview-panel">
                  <div className="preview-heading"><div className="eyebrow">{t.receiptPreview}</div><span className="preview-live-dot" /></div>
                  <ReceiptCard
                    compact
                    t={t}
                    brand={dashboard.societyLabel || dashboard.jobLabel}
                    invoice={{
                      id: 'PREVIEW',
                      invoice_type: 'job',
                      sender_name: dashboard.profileName || t.title,
                      sender_society: dashboard.societyLabel,
                      recipient_name: t.target,
                      title: form.title || t.titleField,
                      subtotal: templateSubtotal,
                      discount_percent: Number(form.discountPercent) || 0,
                      total: Math.max(0, Math.round(templateSubtotal * (100 - (Number(form.discountPercent) || 0)) / 100)),
                      due_date: '—',
                      created_at: new Date().toLocaleDateString(locale === 'id' ? 'id-ID' : 'en-US'),
                      status: 'pending',
                      attachments: getReceiptLines(form.attachments),
                      canPay: false,
                      canCancel: false
                    }}
                    onPay={() => {}}
                    onCancel={() => {}}
                  />
                </aside>
              </div>
            </div>}

            {section === 'commissions' && <div className="section-view">
              <div className="section-heading"><div><div className="eyebrow">{t.commissionHistory}</div><h1>{t.commissions}</h1></div></div>
              <div className="commission-list">{dashboard.commissions?.map((commission) => <article className="commission-row" key={commission.id}>
                <div className="employee-icon"><Users size={17} /></div><div className="template-copy"><strong>{commission.employee_name}</strong><span>Invoice #{commission.invoice_id} · {commission.status}</span></div>
                <strong className="commission-amount">${commission.amount}</strong>
                {commission.status === 'available' && <button className="button" onClick={() => act('payCommission', { id: commission.id, societyJob: selectedSocietyJob }, t.commissionSuccess)}>{t.payCommission}</button>}
              </article>)}{!dashboard.commissions?.length && <div className="empty-state"><CircleDollarSign size={28} /><p>{t.noCommissions}</p></div>}</div>
            </div>}

            {section === 'settings' && <div className="section-view narrow">
              <div className="section-heading"><div><div className="eyebrow">{t.theme}</div><h1>{t.settings}</h1></div></div>
              {dashboard.isAdmin ? <div className="theme-panel">
                <div className="theme-preview"><div className="preview-mark"><Receipt size={20} /></div><strong>{t.title}</strong><span>SRP Billing</span><button className="button">{t.pay}</button></div>
                <div className="theme-controls">{[['accent', t.accent], ['background', t.background], ['surface', t.surface], ['text', t.text]].map(([key, label]) => <label className="color-field" key={key}><span>{label}</span><input type="color" value={theme[key]} onChange={(event) => setTheme({ ...theme, [key]: event.target.value })} /></label>)}</div>
                <button className="button" onClick={async () => { const result = await nui('saveTheme', theme); if (result.ok) setNotice(t.saveTheme); else setNotice(result.error || t.actionFailed); }}>{t.saveTheme}</button>
              </div> : <div className="empty-state"><Settings size={28} /><p>{t.adminOnly}</p></div>}
            </div>}
            </section>
          </div>
        </div>
        <img className="ui-frame" src="./images/tablet-frame.png" alt="" aria-hidden="true" />
      </section>
    </main>
  );
}
