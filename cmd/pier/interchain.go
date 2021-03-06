package main

import (
	"fmt"

	"github.com/meshplus/pier/internal/repo"

	"github.com/meshplus/bitxhub-kit/types"
	rpcx "github.com/meshplus/go-bitxhub-client"
	"github.com/urfave/cli"
)

var interchainCMD = cli.Command{
	Name:  "interchain",
	Usage: "Query interchain info",
	Flags: []cli.Flag{
		cli.StringFlag{
			Name:     "key",
			Usage:    "Specific key.json path",
			Required: true,
		},
	},
	Subcommands: []cli.Command{
		{
			Name:  "ibtp",
			Usage: "Query ibtp by id",
			Flags: []cli.Flag{
				cli.StringFlag{
					Name:     "id",
					Usage:    "Specific ibtp id",
					Required: true,
				},
			},
			Action: getIBTP,
		},
	},
}

func getIBTP(ctx *cli.Context) error {
	id := ctx.String("id")

	repoRoot, err := repo.PathRootWithDefault(ctx.GlobalString("repo"))
	if err != nil {
		return err
	}

	config, err := repo.UnmarshalConfig(repoRoot)
	if err != nil {
		return fmt.Errorf("init config error: %s", err)
	}

	client, err := loadClient(repo.KeyPath(repoRoot), config.Bitxhub.Addr)
	if err != nil {
		return fmt.Errorf("load client: %w", err)
	}

	receipt, err := client.InvokeBVMContract(
		rpcx.InterchainContractAddr,
		"GetIBTPByID",
		rpcx.String(id),
	)
	if err != nil {
		return err
	}

	hash := types.Bytes2Hash(receipt.Ret)

	fmt.Printf("Tx hash: %s\n", hash.Hex())

	response, err := client.GetTransaction(hash.Hex())
	if err != nil {
		return err
	}

	fmt.Println(response)

	return nil
}
