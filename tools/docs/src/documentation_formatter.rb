require 'yaml'
require 'pathname'


class DocumentationFormatter
  def initialize
    @docs_root = '/docs'
  end

  def update_docs_content(docs_dir, ns, repo_name, tag)
    Dir.glob(File.join(docs_dir, '*.md')).each do | file|
      doc = IO.read(file)
      relative_path = Pathname.new(file).relative_path_from(Pathname.new(docs_dir))
      result = update_doc(doc, ns, repo_name, tag, relative_path.to_s)
      IO.write(file, result)
    end
  end

  def update_doc(doc, ns, repo_name, tag, relative_path)
      doc_fm = update_front_matter_data(doc, ns, repo_name, tag, relative_path)
      update_urls(doc_fm, repo_name, tag)
  end

  def update_front_matter_data(doc, ns, repo_name, tag, relative_path)
    data = YAML.load(doc)

    data['page_id'] = ns + data['page_id']
    data['layout'] = 'page-docs'
    data['repo_name'] = repo_name
    data['repo_tag'] = tag
    data['ns'] = ns

    path_without_md_ext = relative_path[0..-4]
    data['permalink'] = @docs_root + '/' + repo_name + '/' + tag + '/' + path_without_md_ext + '/'

    start_of_front_matter = doc.index('---')
    end_of_front_matter = doc.index('---', start_of_front_matter + 3)
    data.to_yaml + doc[end_of_front_matter..-1]
  end

  def update_urls(doc, repo_name, tag)
    # The URLs in the repo docs are designed to work with the local jekyll server,
    # massage them to fit the public web structure.
    # Links have the following format:
    # [Some text](/the/url/)
    #
    # Doc url ==> modified url
    # ------------------------
    # #page-ref ==> #page-ref
    # /my-url/ ==> /docs/repo-name/tag/my-url/
    # https://www.bitcraze.io/fancy_page/ ==> /fancy_page/
    # https://other.domain/fancy_page/ ==> https://other.domain/fancy_page/

    repo_path = @docs_root + '/' + repo_name + '/' + tag
    doc.gsub(/(\[[^\[]*\])\(\s*(\/[^\)]*)\)/, '\1(' + repo_path + '\2)').gsub(/(\[[^\[]*\])\(\s*https:\/\/www.bitcraze.io(\/[^\)]*\))/, '\1(\2')
  end

  def add_name_space_to_node_list(nodes, ns)
    nodes.each do |node|
      if node.key? 'page_id'
        node['page_id'] = ns + node['page_id']
      end

      if node.key? 'subs'
        add_name_space_to_node_list(node['subs'], ns)
      end
    end
  end

  def add_to_docs_menus(docs_menu_file, shared_docs_menus_file, ns)
    repo_menus = YAML.load_file(docs_menu_file)
    add_name_space_to_node_list(repo_menus, ns)

    if File.file? shared_docs_menus_file
      shared_menus = YAML.load_file(shared_docs_menus_file)
    else
      shared_menus = {}
    end

    shared_menus[ns] = repo_menus

    IO.write(shared_docs_menus_file, shared_menus.to_yaml)
  end

end