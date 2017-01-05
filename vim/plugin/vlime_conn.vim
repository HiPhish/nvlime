if !exists('g:vlime_connections')
    let g:vlime_connections = {}
endif

if !exists('g:vlime_next_conn_id')
    let g:vlime_next_conn_id = 1
endif

" VlimeNewConnection([name])
function! VlimeNewConnection(...)
    if a:0 > 0
        let conn_name = a:1
    else
        let conn_name = 'Vlime Connection ' . g:vlime_next_conn_id
    endif
    let conn = vlime#New(
                \ {
                    \ 'id': g:vlime_next_conn_id,
                    \ 'name': conn_name
                \ },
                \ vlime#ui#GetUI())
    let g:vlime_connections[g:vlime_next_conn_id] = conn
    let g:vlime_next_conn_id += 1
    return conn
endfunction

function! VlimeCloseConnection(conn)
    let conn_id = s:NormalizeConnectionID(a:conn)
    let r_conn = remove(g:vlime_connections, conn_id)
    call r_conn.Close()
endfunction

function! VlimeRenameConnection(conn, new_name)
    let conn_id = s:NormalizeConnectionID(a:conn)
    let r_conn = g:vlime_connections[conn_id]
    let r_conn.cb_data['name'] = a:new_name
endfunction

function! VlimeSelectConnection(quiet)
    if len(g:vlime_connections) == 0
        if !a:quiet
            call vlime#ui#ErrMsg('Vlime not connected.')
        endif
        return v:null
    else
        let conn_names = []
        for k in sort(keys(g:vlime_connections), 'n')
            let conn = g:vlime_connections[k]
            let chan_info = ch_info(conn.channel)
            call add(conn_names, k . '. ' . conn.cb_data['name'] .
                        \ ' (' . chan_info['hostname'] . ':' . chan_info['port'] . ')')
        endfor

        echohl Question
        echom 'Which connection to use?'
        echohl None
        let conn_nr = inputlist(conn_names)
        if conn_nr == 0
            if !a:quiet
                call vlime#ui#ErrMsg('Canceled.')
            endif
            return v:null
        else
            let conn = get(g:vlime_connections, conn_nr, v:null)
            if type(conn) == v:t_none
                if !a:quiet
                    call vlime#ui#ErrMsg('Invalid connection ID: ' . conn_nr)
                endif
                return v:null
            else
                return conn
            endif
        endif
    endif
endfunction

" VlimeGetConnection([quiet])
function! VlimeGetConnection(...) abort
    let quiet = vlime#GetNthVarArg(a:000, 0, v:false)

    if !exists('b:vlime_conn') ||
                \ (type(b:vlime_conn) != v:t_none &&
                    \ !b:vlime_conn.IsConnected()) ||
                \ (type(b:vlime_conn) == v:t_none && !quiet)
        if len(g:vlime_connections) == 1 && !exists('b:vlime_conn')
            let b:vlime_conn = g:vlime_connections[keys(g:vlime_connections)[0]]
        else
            let conn = VlimeSelectConnection(quiet)
            if type(conn) == v:t_none
                if quiet
                    " No connection found. Set this variable to v:null to
                    " make it 'quiet'
                    let b:vlime_conn = conn
                else
                    return conn
                endif
            else
                let b:vlime_conn = conn
            endif
        endif
    endif
    return b:vlime_conn
endfunction

function! s:NormalizeConnectionID(id)
    if type(a:id) == v:t_dict
        return a:id.cb_data['id']
    else
        return a:id
    endif
endfunction