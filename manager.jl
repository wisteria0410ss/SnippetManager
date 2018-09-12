using TerminalMenus
import JSON

snippetJson = Dict()

function selectJson()
    l = String[]
    for f in readdir(homedir()*"/.config/Code/User/snippets/")
        if endswith(f, ".json")
            append!(l, [f])
        end
    end
    if length(l) == 0
        println("JSON ファイルが見つかりませんでした。")
        exit(1)
    end

    menu = RadioMenu(l)
    run(`clear`)
    choice = request("編集するファイルを選択してください。\n[↑][↓]\t移動\n[Enter]\t選択\n[q]\t終了\n", menu)

    if choice == -1
        run(`clear`)
        exit(0)
    end

    readJson(l[choice])
    selectAction(l[choice])
end

function readJson(filename)
    global snippetJson

    s=""
    open(homedir()*"/.config/Code/User/snippets/"*filename) do f
        lines = readlines(f)
        for l in lines
            if !startswith(strip(l),"//")
                s=s*l*"\n"
            end
        end
    end

    snippetJson = JSON.parse(s)
end

function selectAction(filename)
    menu = RadioMenu(["新規スニペットの追加", "既存スニペットの編集", "スニペットの削除", "変更を保存して終了", "変更を破棄して終了"])
    run(`clear`)
    choice = request(filename*"について行う動作を選択してください。\n[↑][↓]\t移動\n[Enter]\t選択\n[q]\t変更を破棄して終了\n", menu)

    if choice == -1
        selectJson()
    elseif choice == 1
        addSnippet(filename)
    elseif choice == 2
        modifySnippet(filename)
    elseif choice == 3
        deleteSnippet(filename)
    elseif choice == 4
        open(homedir()*"/.config/Code/User/snippets/"*filename, "w") do f
            write(f,JSON.json(snippetJson))
        end
        selectJson()
    else
        selectJson()
    end
end

function addSnippet(filename)
    print("\n(キャンセル: 空白)\nスニペット名: ")
    name = readline()
    if name == ""
        selectAction(filename)
        return
    end
    if name in keys(snippetJson)
        println("その名前のスニペットは既に存在します。")
        addSnippet(filename)
        return
    end

    print("prefix: ")
    prefix = readline()
    if prefix == ""
        selectAction(filename)
        return
    end

    print("description: ")
    desc = readline()
    if desc == ""
        selectAction(filename)
        return
    end

    tmpfile = homedir()*"/.config/Code/User/snippets/"*filename*".snippet_body.txt"
    run(Cmd(["touch", tmpfile]))
    run(Cmd(["editor", tmpfile]))

    body = String[]
    open(tmpfile) do f
        body = readlines(f)
    end

    run(Cmd(["rm", tmpfile]))

    d=Dict("prefix" => prefix, "body" => body, "description" => desc)
    snippetJson[name]=d

    selectAction(filename)
end

function modifySnippet(filename)
    names = String[s for s in keys(snippetJson)]

    if(length(names)==0)
        menu = RadioMenu(["OK"])
        run(`clear`)
        choice = request(filename*"にはスニペットがありません。", menu)
        selectAction(filename)
        return
    end

    menu = RadioMenu(names)
    run(`clear`)
    choice = request(filename*"内の編集するスニペットを選択してください。\n[↑][↓]\t移動\n[Enter]\t選択\n[q]\tキャンセル\n", menu)
    if choice == -1
        selectAction(filename)
        return
    else
        menu = RadioMenu(["スニペット名", "prefix", "body", "description"])
        item = request("\n編集する項目を選択してください。", menu)
        if item == -1
            modifySnippet(filename)
            return
        elseif item == 1
            println("\n現在のスニペット名: "*names[choice])
            print("新しいスニペット名(キャンセル: 空白): ")
            name = readline()
            if name!="" && name!=names[choice]
                snippetJson[name] = snippetJson[names[choice]]
                delete!(snippetJson, names[choice])
            end
            modifySnippet(filename)
            return
        elseif item == 2
            println("\n現在のprefix: "*snippetJson[names[choice]]["prefix"])
            print("新しいprefix(キャンセル: 空白): ")
            prefix = readline()
            if prefix != ""
                snippetJson[names[choice]]["prefix"] = prefix
            end
            modifySnippet(filename)
            return
        elseif item == 3
            tmpfile = homedir()*"/.config/Code/User/snippets/"*filename*".snippet_body.txt"
            run(Cmd(["touch", tmpfile]))
            open(tmpfile,"w") do f
                for ln in snippetJson[names[choice]]["body"]
                    write(f, ln*"\n")
                end
            end
            run(Cmd(["editor", tmpfile]))
        
            body = String[]
            open(tmpfile) do f
                body = readlines(f)
            end
        
            run(Cmd(["rm", tmpfile]))
            snippetJson[names[choice]]["body"] = body
            modifySnippet(filename)
            return
        else
            println("\n現在のdescription: "*snippetJson[names[choice]]["description"])
            print("新しいdescription(キャンセル: 空白): ")
            desc = readline()
            if desc != ""
                snippetJson[names[choice]]["description"] = desc
            end
            modifySnippet(filename)
            return
        end
    end
end

function deleteSnippet(filename)
    names = String[s for s in keys(snippetJson)]

    if(length(names)==0)
        menu = RadioMenu(["OK"])
        run(`clear`)
        choice = request(filename*"にはスニペットがありません。", menu)
        selectAction(filename)
        return
    end

    menu = RadioMenu(names)
    run(`clear`)
    choice = request(filename*"から削除するスニペットを選択してください。\n[↑][↓]\t移動\n[Enter]\t選択\n[q]\tキャンセル\n", menu)
    if choice == -1
        selectAction(filename)
    else
        menu = RadioMenu(["はい", "いいえ"])
        conf = request("\nスニペット"*names[choice]*"を削除してもよろしいですか。", menu)
        if conf==1
            delete!(snippetJson, names[choice])
        end

        deleteSnippet(filename)
    end
end

selectJson()