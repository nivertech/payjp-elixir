defmodule Payjp.CardTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  @moduletag :card

  setup_all do
    use_cassette "card_test/setup", match_requests_on: [:query, :request_body] do
      Payjp.Customers.delete_all
      customer = Helper.create_test_customer "customer_test1@example.com"

      on_exit fn ->
        use_cassette "card_test/teardown1", match_requests_on: [:query, :request_body] do
          Payjp.Customers.delete customer.id
        end
      end

      new_card = [
        number: "4242424242424242",
        cvc: 123,
        exp_month: 12,
        exp_year: 2020,
        metadata: [
          test_field: "test val"
        ],
      ]
      new_card2 = [
        number: "4242424242424242",
        cvc: 123,
        exp_month: 02,
        exp_year: 2020,
        metadata: [
          test_field: "test val2"
        ],
      ]
      case Payjp.Cards.create :customer, customer.id, new_card2 do
        {:ok, card2} ->
          case Payjp.Cards.create :customer, customer.id, new_card do
            {:ok, card} ->
            on_exit fn ->
              use_cassette "card_test/teardown2", match_requests_on: [:query, :request_body] do
                Payjp.Cards.delete :customer, customer.id, card.id
                Payjp.Cards.delete :customer, customer.id, card2.id
              end
            end
            {:ok, [customer: customer, card: card, card2: card2]}
            {:error, err} -> flunk err
          end
          {:error, err} -> flunk err
      end
    end
  end

  @tag disabled: false
  test "Metadata works", %{customer: _, card: card, card2: _}  do
    assert card.metadata["test_field"] == "test val"
  end

  @tag disabled: false
  test "List works", %{customer: customer, card: _, card2: _}  do
    use_cassette "card_test/list", match_requests_on: [:query, :request_body] do
      case Payjp.Cards.list :customer, customer.id, [] do
        {:ok, res} ->
          assert length(res[:data]) == 3
        {:error, err} -> flunk err
      end
    end
  end

  @tag disabled: false
  test "List w/key works", %{customer: customer, card: _, card2: _}  do
    use_cassette "card_test/list_with_key", match_requests_on: [:query, :request_body] do
      case Payjp.Cards.list :customer, customer.id, Payjp.config_or_env_key, [] do
        {:ok, res} ->
          assert length(res[:data]) == 3
          {:error, err} -> flunk err
      end
    end
  end

  @tag disabled: false
  test "Retrieve all works", %{customer: customer, card: _, card2: _} do
    use_cassette "card_test/all", match_requests_on: [:query, :request_body] do
      case Payjp.Cards.all :customer, customer.id do
        {:ok, cards} ->
          assert length(cards) > 0
          {:error, err} -> flunk err
      end
    end
  end

  @tag disabled: false
  test "Retrieve w/key all works", %{customer: customer, card: _, card2: _} do
    use_cassette "card_test/all_with_key", match_requests_on: [:query, :request_body] do
      case Payjp.Cards.all :customer, customer.id, Payjp.config_or_env_key, [], [limit: 100] do
        {:ok, cards} ->
          assert length(cards) > 0
          {:error, err} -> flunk err
      end
    end
  end

  @tag disabled: false
  test "Create works", %{customer: _, card: card, card2: _} do
    assert card.id
  end

  @tag disabled: false
  test "Create w/opts  works", %{customer: customer} do
    use_cassette "card_test/create_with_options", match_requests_on: [:query, :request_body] do
      token = Helper.create_test_token
      opts = [
        card: token.id
      ]
      case Payjp.Cards.create :customer, customer.id, opts do
        {:ok, card}   ->
          assert card.customer == customer.id
          assert card.id
          {:error, err} -> flunk err
      end
    end
  end

  @tag disabled: false
  test "Create w/opts w/key works", %{customer: customer} do
    use_cassette "card_test/create_with_options_with_key", match_requests_on: [:query, :request_body] do
      params = [
        card: [
          number: "4242424242424242",
          exp_month: 10,
          exp_year: 2020,
          cvc: "123"
        ]
      ]
      token = Helper.create_test_token(params)
      opts = [
        card: token.id
      ]

      case Payjp.Cards.create :customer, customer.id, opts, Payjp.config_or_env_key do
        {:ok, card}   ->
          assert card.customer == customer.id
          assert card.id
        {:error, err} ->
          flunk "err"
      end
    end
  end

  @tag disabled: false
  test "Retrieve single works", %{customer: customer, card: card, card2: _} do
    use_cassette "card_test/get", match_requests_on: [:query, :request_body] do
      case Payjp.Cards.get :customer, customer.id, card.id do
        {:ok, found} -> assert found.id == card.id
        {:error, err} -> flunk err
      end
    end
  end

  @tag disabled: false

  test "Delete works", %{customer: customer, card: card, card2: _} do
    use_cassette "card_test/delete", match_requests_on: [:query, :request_body] do
      case Payjp.Cards.delete :customer, customer.id, card.id do
        {:ok, res} -> assert res.deleted
        {:error, err} -> flunk err
      end
    end
  end

  @tag disabled: false
  test "Delete w/key works", %{customer: customer, card: _, card2: card2} do
    use_cassette "card_test/delete_with_key", match_requests_on: [:query, :request_body] do
      case Payjp.Cards.delete :customer, customer.id, card2.id, Payjp.config_or_env_key do
        {:ok, res} -> assert res.deleted
        {:error, err} -> flunk err
      end
    end
  end

  @tag disabled: false
  test "Delete all works", %{customer: customer, card: _, card2: _} do
    use_cassette "card_test/delete_all", match_requests_on: [:query, :request_body] do
      Payjp.Cards.delete_all :customer, customer.id

      use_cassette "card_test/delete_all_count", match_requests_on: [:query, :request_body] do
        case Payjp.Cards.all :customer, customer.id do
          {:ok, cards} -> assert length(cards) == 0
          {:error, err} -> flunk err
        end
      end
    end
  end

  @tag disabled: false
  test "Delete all w/key works", %{customer: customer, card: _, card2: _} do
    use_cassette "card_test/delete_all_with_key", match_requests_on: [:query, :request_body] do
      Payjp.Cards.delete_all :customer, customer.id, Payjp.config_or_env_key

      case Payjp.Cards.all :customer, customer.id do
        {:ok, cards} -> assert length(cards) == 0
        {:error, err} -> flunk err
      end
    end
  end

  @tag disabled: false
  test "Update with key works", %{customer: customer} do
    use_cassette "card_test/update", match_requests_on: [:query, :request_body] do
      new_card = [
        number: "4242424242424242",
        cvc: 123,
        exp_month: 12,
        exp_year: 2020
      ]

      { :ok, card } = Payjp.Cards.create :customer, customer.id, new_card

      case Payjp.Cards.update(:customer, customer.id, card.id, [exp_month: 11], Payjp.config_or_env_key) do
        {:ok, res} -> assert res.exp_month == 11
        {:error, err} -> flunk err
      end
    end
  end

  @tag disabled: false
  test "Update works", %{customer: customer} do
    use_cassette "card_test/update", match_requests_on: [:query, :request_body] do
      new_card = [
        number: "4242424242424242",
        cvc: 123,
        exp_month: 12,
        exp_year: 2020
      ]

      { :ok, card } = Payjp.Cards.create :customer, customer.id, new_card

      case Payjp.Cards.update(:customer, customer.id, card.id, [exp_month: 11], Payjp.config_or_env_key) do
        {:ok, res} -> assert res.exp_month == 11
        {:error, err} -> flunk err
      end
    end
  end
end
