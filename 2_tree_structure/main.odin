#+feature dynamic-literals

package main

import "core:fmt"

TreeNode :: struct {
	parent: ^TreeNode,
	children: [dynamic]^TreeNode,
	text: string,
}

add_child :: proc(parent: ^TreeNode, text: string) -> ^TreeNode {
	child := new(TreeNode)
	child.parent = parent
	child.text = text
	append(&parent.children, child)
	return child
}

treenode_print :: proc(treeNode: ^TreeNode) {
	if treeNode == nil {
		return
	}

	if treeNode.parent == nil {
		fmt.println("root:", treeNode.text)
	} else {
		fmt.println("parent:", treeNode.parent.text, ":", treeNode.text)
	}

	for &child in treeNode.children {
		treenode_print(child)
	}
}

main :: proc() {
	tree: TreeNode
	tree.text = "hello"
	c1 := add_child(&tree, "world1")
	add_child(c1, "bark")

	add_child(&tree, "world2")
	treenode_print(&tree)
}
